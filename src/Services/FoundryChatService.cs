using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Options;

namespace ZavaStorefront.Services;

public class FoundryChatService
{
    private const string CognitiveServicesScope = "https://cognitiveservices.azure.com/.default";
    private readonly ILogger<FoundryChatService> _logger;
    private readonly FoundryOptions _options;
    private readonly HttpClient _httpClient;
    private readonly TokenCredential _credential;

    public FoundryChatService(
        HttpClient httpClient,
        ILogger<FoundryChatService> logger,
        IOptions<FoundryOptions> options)
    {
        _httpClient = httpClient;
        _logger = logger;
        _options = options.Value;
        _credential = new DefaultAzureCredential();
    }

    public async Task<string> SendMessageAsync(string message, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.Endpoint) || string.IsNullOrWhiteSpace(_options.DeploymentName))
        {
            throw new InvalidOperationException("Foundry configuration is missing. Check Foundry settings.");
        }

        try
        {
            var requestUri = BuildChatCompletionsUri();
            var token = await _credential.GetTokenAsync(
                new TokenRequestContext(new[] { CognitiveServicesScope }),
                cancellationToken);

            using var request = new HttpRequestMessage(HttpMethod.Post, requestUri);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);
            AddResourceIdHeader(request, requestUri);

            var payload = new
            {
                model = _options.DeploymentName,
                messages = new[]
                {
                    new { role = "user", content = message }
                },
                max_tokens = 200,
                temperature = 0.7
            };

            request.Content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json");

            using var response = await _httpClient.SendAsync(request, cancellationToken);
            var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Foundry request failed with status {StatusCode}: {ResponseBody}",
                    response.StatusCode,
                    responseBody);
                throw new InvalidOperationException("Foundry request failed.");
            }

            return ExtractResponseText(responseBody);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Foundry request failed.");
            throw new InvalidOperationException("Foundry request failed.");
        }
    }

    private Uri BuildChatCompletionsUri()
    {
        if (string.IsNullOrWhiteSpace(_options.Endpoint))
        {
            throw new InvalidOperationException("Foundry OpenAI endpoint is missing.");
        }

        var rawEndpoint = _options.Endpoint.Trim();
        if (!Uri.TryCreate(rawEndpoint, UriKind.Absolute, out var parsed))
        {
            throw new InvalidOperationException("Foundry endpoint is invalid.");
        }

        var path = parsed.AbsolutePath.TrimEnd('/');
        if (path.EndsWith("/chat/completions", StringComparison.OrdinalIgnoreCase))
        {
            return parsed;
        }

        var newPath = path.EndsWith("/models", StringComparison.OrdinalIgnoreCase) ||
                      path.EndsWith("/openai/v1", StringComparison.OrdinalIgnoreCase)
            ? $"{path}/chat/completions"
            : $"{path}/openai/v1/chat/completions";

        var builder = new UriBuilder(parsed)
        {
            Path = newPath
        };

        return builder.Uri;
    }

    private void AddResourceIdHeader(HttpRequestMessage request, Uri requestUri)
    {
        var resourceId = _options.ResourceId?.Trim();
        var isRegionalEndpoint = requestUri.Host.EndsWith(".api.cognitive.microsoft.com", StringComparison.OrdinalIgnoreCase);

        if (isRegionalEndpoint && string.IsNullOrWhiteSpace(resourceId))
        {
            throw new InvalidOperationException("Foundry ResourceId is required for regional endpoints.");
        }

        if (!isRegionalEndpoint || string.IsNullOrWhiteSpace(resourceId))
        {
            return;
        }

        request.Headers.TryAddWithoutValidation("x-ms-azure-resourceid", resourceId);
        request.Headers.TryAddWithoutValidation("x-ms-azure-resource-id", resourceId);
    }

    private static string ExtractResponseText(string responseBody)
    {
        using var document = JsonDocument.Parse(responseBody);

        if (document.RootElement.TryGetProperty("choices", out var choices) && choices.GetArrayLength() > 0)
        {
            var firstChoice = choices[0];
            if (firstChoice.TryGetProperty("message", out var message) &&
                message.TryGetProperty("content", out var content))
            {
                return content.GetString() ?? string.Empty;
            }
        }

        return string.Empty;
    }
}
