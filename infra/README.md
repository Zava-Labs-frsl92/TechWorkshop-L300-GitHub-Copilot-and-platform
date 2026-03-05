# Infrastructure

Bicep templates for the ZavaStorefront dev environment.

## Structure

- main.bicep: Orchestrates all modules
- modules/: Individual resource modules
- main.parameters.json: Sample parameters for dev

## Deployment

Use Azure Developer CLI:

- azd provision --preview
- azd up
