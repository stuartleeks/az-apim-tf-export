{% with tf_diagnostic_id=diagnostic.id | last_segment | to_terraform_id %}
{# Since we're deploying via Terraform, we should have consistent logger names across environments #}
{# Use this fact to dynamically build the logger ID for target environments #}
{# #}
{# azurerm doesn't currently have setting for custom metrics so we use azapi for now #}
{# GH issue: https://github.com/hashicorp/terraform-provider-azurerm/issues/28487 #}
resource "azapi_resource" "{{ tf_api_id }}_{{ tf_diagnostic_id }}" {
  count                     = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  type                      = "Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01"
  parent_id                 = azurerm_api_management_api.{{ tf_api_id }}[0].id
  name                      = {{ diagnostic.name | quote }}
  schema_validation_enabled = false
  body                      = {
    properties = {
      loggerId = "${data.azurerm_api_management.apim.id}/loggers/{{ diagnostic.logger_id | last_segment }}"
      sampling = {
        samplingType = {{ diagnostic.sampling.sampling_type | quote }}
        percentage   = {{ diagnostic.sampling.percentage }}
      }
{%- if diagnostic.always_log %}
      alwaysLog               = "allErrors"
{%- endif %}
      metrics                 = {{ diagnostic.metrics | to_terraform_bool }}
      logClientIp             = {{ diagnostic.log_client_ip | to_terraform_bool }}
      verbosity               = {{ diagnostic.verbosity | quote }}
      httpCorrelationProtocol = {{ diagnostic.http_correlation_protocol | quote }}
      frontend = {
        request = {
          body = {
            bytes = {{ diagnostic.frontend.request.body.bytes }}
          }
          headers = [ {{ diagnostic.frontend.request.headers | quote | join(", ") }} ]
        }
        response = {
          body = {
            bytes = {{ diagnostic.frontend.response.body.bytes }}
          }
          headers = [ {{ diagnostic.frontend.response.headers | quote | join(", ") }} ]
        }
      }
      backend = {
        request = {
          body = {
            bytes = {{ diagnostic.backend.request.body.bytes }}
          }
          headers = [ {{ diagnostic.backend.request.headers | quote | join(", ") }} ]
        }
        response = {
          body = {
            bytes = {{ diagnostic.backend.response.body.bytes }}
          }
          headers = [ {{ diagnostic.backend.response.headers | quote | join(", ") }} ]
        }
      }
    }
  }
}
{%- endwith %}