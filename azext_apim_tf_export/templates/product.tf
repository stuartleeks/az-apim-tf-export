{% with tf_product_id=product.id | last_segment | to_terraform_id %}
resource "azurerm_api_management_product" "{{ tf_product_id }}" {
  count                 = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  approval_required     = {{ product.approval_required | to_terraform_bool }}
  display_name          = {{ product.display_name | quote }}
  product_id            = {{ product.id | last_segment | quote }}
  published             = {{ (product.state == "published") | to_terraform_bool }}
  subscription_required = {{ product.subscription_required | to_terraform_bool}}
  description           = {{ product.description | quote }}
  subscriptions_limit   = {{ product.subscriptions_limit or "null"}}
  terms                 = {{ product.terms | quote }}
}
{%- if product_policy_path %}

resource "azurerm_api_management_product_policy" "{{ tf_product_id }}" {
  count                = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  product_id          = azurerm_api_management_product.{{ tf_product_id }}[0].product_id
  xml_content         = file("${path.module}/{{ product_policy_path }}")
}
{% endif %}
{%- for api_id, environments in product_apis.items() %}
{%- with tf_product_id=product.id | last_segment | to_terraform_id, tf_api_id=api_id | last_segment | to_terraform_id %}
resource "azurerm_api_management_product_api" "{{tf_product_id}}_{{tf_api_id}}" {
  count                = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  product_id          = azurerm_api_management_product.{{tf_product_id}}[0].product_id
  api_name            = azurerm_api_management_api.{{tf_api_id}}[0].name
}
{%- endwith %}
{%- endfor %}
{% endwith %}