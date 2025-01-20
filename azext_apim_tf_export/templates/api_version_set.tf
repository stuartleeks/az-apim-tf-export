{% with tf_api_version_set_id=api_version_set.id | last_segment | to_terraform_id %}
resource "azurerm_api_management_api_version_set" "version_set_{{ tf_api_version_set_id }}" {
  count               = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  name                = {{ api_version_set.name | quote }}
  display_name        = {{ api_version_set.display_name | quote }}
  versioning_scheme   = {{ api_version_set.versioning_scheme | quote }}
  description         = {{ api_version_set.description | empty_to_none | quote }}
  version_header_name = {{ api_version_set.version_header_name | quote }}
  version_query_name  = {{ api_version_set.version_query_name | quote }}
}
{% endwith %}