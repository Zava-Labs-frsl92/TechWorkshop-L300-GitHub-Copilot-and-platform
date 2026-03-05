# GitHub Actions quickstart (App Service container)

This workflow builds a container image for the ASP.NET Core app and deploys it to the existing App Service and ACR created by the infra Bicep.

## GitHub secrets

Add these repository secrets:

- AZURE_CREDENTIALS: JSON string for a service principal with access to the resource group.
	Example format:
	{"clientId":"<app-id>","clientSecret":"<secret>","subscriptionId":"<sub-id>","tenantId":"<tenant-id>"}

## GitHub variables

Add these repository variables:

- AZURE_RESOURCE_GROUP: Resource group name where infra was deployed.
- AZURE_WEBAPP_NAME: App Service name created by the Bicep deployment.
- AZURE_ACR_NAME: ACR name created by the Bicep deployment.
- IMAGE_NAME (optional): Container image name; should match the Bicep parameter containerImageName (default zavastorefront).

## Create the AZURE_CREDENTIALS secret

Use Azure CLI to create a service principal scoped to the resource group and output the JSON needed by `AZURE_CREDENTIALS`:

```
az ad sp create-for-rbac \
	--name "gh-actions-zavastorefront" \
	--role Contributor \
	--scopes /subscriptions/<sub-id>/resourceGroups/<rg-name> \
	--json-auth
```

Copy the full JSON output into the `AZURE_CREDENTIALS` GitHub secret. Store it as a single-line JSON string.

If `--json-auth` is not recognized, upgrade Azure CLI to a recent version and retry.


## Notes

- If you change the image name or tag in infra, update IMAGE_NAME in GitHub variables to match.
- To find the Web App or ACR names, check the Azure portal or list them in the resource group with az webapp list and az acr list.
