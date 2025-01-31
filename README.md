# az-apim-tf-export

**NOTE: This extension is experimental and not supported**

This repository contains an extension for the Azure CLI (`az`) that allows exporting API and Product configuration from Azure API Management to Terraform configuration files.

This allows you to work in a development deployment of APIM and then export the configration to Terraform to deploy to other environments (e.g. staging, production).

If you are not using Terraform (or don't want to manage your API Management configuration in Terraform), you might be interested in the [APIOps](https://github.com/Azure/apiops) project instead.

- [az-apim-tf-export](#az-apim-tf-export)
	- [Installation](#installation)
	- [Usage](#usage)
	- [How it works](#how-it-works)
	- [Limitations](#limitations)
	- [Handling differences in environments](#handling-differences-in-environments)
	- [Config file](#config-file)
		- [JSON](#json)
		- [YAML](#yaml)
		- [Default config](#default-config)


## Installation

The repository has a GitHub release that contains a wheel file for the extension.
To install directly from GitHub, run the following command:

```bash
# Download and install from the GitHub release
az extension add --source https://github.com/stuartleeks/az-apim-tf-export/releases/download/v0.0.1/apim_tf_export-0.0.1-py2.py3-none-any.whl
```

If you prefer to build the extension yourself, run `make build-wheel` from the root of the project repo.
The repo contains a VS Code dev container that has all the required dependencies installed.

After building the extension, you can install it using `make add-extension`.
If you want to install the extension in a different environment after building then run `az extension add --source <path to wheel file>`.

## Usage

After installing the extension, you can use the `az apim export-to-terraform` command to export the configuration of an APIs and Products.
Note that the extension uses the `az` CLI to authenticate so you will need to be logged in to the Azure CLI before running the command.

For a guided tour of using the extension see the [walkthrough](docs/walkthrough.md) included in the repo.

The command has the following parameters:

| Name                    | Description                                                                                                                                                                |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--resource-group`/`-g` | [Required] The name of the resource group that contains the APIM service.                                                                                                  |
| `--service-name`        | [Required] The name of the APIM service.                                                                                                                                   |
| `--output-folder`       | [Required] The folder to export the configuration to, typically a dedicated subfolder of your Terraform project. **IMPORTANT** all content in this folder will be deleted. |
| `--config`              | [Optional] The path to a [config file](#config-file) to control the export. If not specified, the [default configuration](#default-config) will be used.                   |
| `--yes`/`-y`            | [Optional] Bypass the confirmation prompt.                                                                                                                                 |

## How it works

When the extension is run it will export the configuration of the specified APIM resources to a Terraform module in the folder specified by the `--output-folder` parameter.

This module can be imported into the your main Terraform configuration.
The following variables need to be passed to the module:

| Name                   | Description                                                          |
| ---------------------- | -------------------------------------------------------------------- |
| `location`             | The location of the APIM service                                     |
| `resource_group_name`  | The name of the resource group that contains the APIM service        |
| `apim_management_name` | The name of the APIM service                                         |
| `environment`          | The environment being targetting by the deployment (e.g. test, prod) |

The `environment` variable is used to allow you to prevent the API configuration being deployed back to the environment that it was originally exported from (potentially overwriting changes being made directly in the APIM Developer Portal that haven't yet been exported). If you don't need this functionality then you can just set this to a fixed value to match the environment specified in the config (if you are using the default config then use the value `all`)

## Limitations

Currently the extension supports exporting the following APIM resources:

- API
- API Policy
- API Operation
- API Operation Policy
- API Version Set
- API Diagnostic Settings
- Product
- Product Policy
- Product to API Mapping

By design, the extension does not export the following resources as they relate to the target environment and should be configured as part of the APIM Service deployment:

- Backend APIs
- Named Values
- APIM Loggers

**NOTE:** The extension does not currently support exporting APIs that use API revisions.

Future versions of the extension may support exporting additional resources, such as:

- API Revisions
- Product Groups
- Product Tags

## Handling differences in environments

When running the export script, the API and Product definitions are exported to Terraform and then applied to other environments.
This means that the same API configuration is applied to all environments.
However, there are some aspects of the API behaviour that needs to change across environments.
A common example is the base URL for an API.
A simple way to manage this is to set up named backends in APIM (via Terraform) and then use the `set-backend-service` policy to set the backend for an API to a configured named backend (keeping the name consistent across environments):

```xml
<!-- example policy snippet -->
<inbound>
    <set-backend-service backend-id="openai" />
    <base />
</inbound>
```

If there are other values that need to vary in API policies, APIM named values can be used.
For example, if you are using the `validate-jwt` policy you may wish to vary the EntraID tenant and audience values across environments.
To do this, you could use Terraform to set up named values for `aad_tenant` and `aad_scope` and then reference these in the policy:

```xml
<validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Not authorized">
    <openid-config url="https://login.microsoftonline.com/{{aad_tenant}}/.well-known/openid-configuration" />
    <required-claims>
        <claim name="aud" match="all">
            <value>{{aad_scope}}</value>
        </claim>
    </required-claims>
</validate-jwt>
```


## Config file

The `export-to-terraform` command allows you to specify a config file to control which APIs and Products are exported.
This file can be in either JSON or YAML format.

### JSON

An example of a JSON config file is shown below:

```json
{
	"apis": {
		"my-api-1": {
			"environments" : ["env2"]
		},
		"my-api-2": {
			"environments" : ["env2", "env3"]
		},
		"other-api-*" : {
			"environments" : ["env2", "env3"]
		}
	},
	"products": {
		"my-product" : {
			"environments" : ["env2", "env3"]
		}
	}
}
```

In this example, the `my-api-1` and `my-api-2` APIs will be exported.
The `my-api-1` API will have a condition applied to ensure that it is only deployed to the `env2` environment, while the `my-api-2` API will be deployed to both the `env2` and `env3` environments.

Additionally, the `other-api-*` wildcard will match any API with a name that starts with `other-api-` and they will be deployed to the `env2` and `env3` environments.

The `my-product` product will also be exported and deployed to the `env2` and `env3` environments.

### YAML

An example of a YAML config file is shown below:

```yaml
apis:
  my-api-1:
    environments:
      - env2
  my-api-2:
    environments:
      - env2
      - env3
  other-api-*:
    environments:
      - env2
      - env3
products:
  my-product:
    environments:
      - env2
      - env3
```

This YAML config file is functionally equivalent to the JSON example shown above.

### Default config

If a config file is not specified, the following default config will be used:

```json
{
	"apis": {
		"*": {
			"environments": ["all"]
		}
	},
	"products": {
		"*": {
			"environments": ["all"]
		}
	}
}
```

