{% with tf_api_id=api.id | last_segment | to_terraform_id %}
resource "azurerm_api_management_api" "{{ tf_api_id }}" {
  count                = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name  = var.resource_group_name
  api_management_name  = var.api_management_name
  name                 = {{ api.name | quote }}
  revision             = {{ api.api_revision | quote }}
  api_type             = {{ api.api_type | quote }}
  display_name         = {{ api.display_name | quote }}
  path                 = {{ api.path | quote}}
  protocols            = [{{ api.protocols | quote | join(", ") }}]
{%- if api.contact %}  contact {
    email = {{ api.contact.email | quote }}
    name  = {{ api.contact.name | quote }}
    phone = {{ api.contact.phone | quote }}
  }
{%- endif %}
  description          = {{ api.description | quote }}
{%- if api.license %}
  license {
    name = {{ api.license.name | quote }}
    url  = {{ api.license.url | quote }}
  }
{%- endif %}
{%- if api.authentication_settings.o_auth2 %}
  oauth2_authorization {
    authorization_server_id = {{ api.authentication_settings.o_auth2.authorization_server_id | quote }}
    scope                   = {{ api.authentication_settings.o_auth2.scope | quote }}
  }
{%- endif %}
{%- if api.authentication_settings.openid %}
  openid_authentication {
    openid_provider_id           = {{ api.authentication_settings.openid.authorization_server_id | quote }}
    bearer_token_sending_methods = {{ api.authentication_settings.openid.scope | quote | join(", ")}}
  }
{%- endif %}
  service_url          = {{ api.service_url | quote}}
  subscription_key_parameter_names {
    header = {{ api.subscription_key_parameter_names.header | quote }}
    query  = {{ api.subscription_key_parameter_names.query | quote }}
  }
  subscription_required = {{ api.subscription_required | to_terraform_bool }}
  terms_of_service_url  = {{ api.terms_of_service_url | quote }}
  version               = {{ api.api_version | quote }}
  version_set_id        = {% if api.api_version_set_id %}azurerm_api_management_api_version_set.version_set_{{ api.api_version_set_id | last_segment | to_terraform_id }}[0].id{% else %}null{% endif %}
  revision_description  = {{ api.api_revision_description | empty_to_none | quote }}
  version_description   = {{ api.api_version_description | empty_to_none | quote }}
}
{%- if api_policy_path %}

resource "azurerm_api_management_api_policy" "{{ tf_api_id }}" {
  count                = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  api_name            = azurerm_api_management_api.{{ tf_api_id }}[0].name
  xml_content         = file("${path.module}/{{ api_policy_path }}")
}
{% endif %}
{%- for diagnostic in diagnostics %}
{%- include 'api_diagnostic.tf' %}
{%- endfor %}
{%- for schema in schemas %}
{%- include 'api_schema.tf' %}
{%- endfor %}
{%- for operation in operations %}
{%- include 'api_operation.tf' %}
{%- endfor %}
{% endwith %}