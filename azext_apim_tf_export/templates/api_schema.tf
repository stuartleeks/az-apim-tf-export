{% with tf_schema_id=schema.id | last_segment | to_terraform_id %}
resource "azurerm_api_management_api_schema" "{{ tf_api_id }}_{{ tf_schema_id }}" {
  count               = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  api_name            = azurerm_api_management_api.{{ tf_api_id }}[0].name
  schema_id           = {{ schema.id | last_segment | quote }}
  content_type        = {{ schema.content_type | quote }}
  components          = file("${path.module}/{{ schema_paths[schema.id] }}")
}
{% endwith -%}