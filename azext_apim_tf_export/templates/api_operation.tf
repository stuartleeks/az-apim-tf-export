{% with tf_operation_id=operation.id | last_segment | to_terraform_id %}
resource "azurerm_api_management_api_operation" "{{ tf_api_id }}--{{ tf_operation_id }}" {
  count               = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  api_name            = azurerm_api_management_api.{{ tf_api_id }}[0].name
  operation_id        = {{ operation.id | last_segment | quote }}
  display_name        = {{ operation.display_name | quote }}
  method              = {{ operation.method | quote }}
  url_template        = {{ operation.url_template | quote }}
  description         = {{ operation.description | empty_to_none | quote }}
{# request #}
{%- if operation.request %}
  request {
    description = {{ operation.request.description | quote }}
{# request.header #}
{%- for header in operation.request.headers %}

    header {
      name          = {{ header.name | quote }}
      required      = {{ header.required | to_terraform_bool }}
      type          = {{ header.type | quote }}
      description   = {{ header.description | empty_to_none | quote }}
      default_value = {{ header.default_value | quote }}
      values        = [{{ header.values | quote | join(", ") }}]
      type_name     = {{ header.type_name | quote }}
{%- if header.schema_id %}
      schema_id     = azurerm_api_management_api_schema.{{ tf_api_id  }}_{{ header.schema_id | last_segment | to_terraform_id }}[0].schema_id
{%- endif %}
    }
{%- endfor %}
{# request.query_parameter #}
{%- for query_parameter in operation.request.query_parameters %}
{# ignoring example #}

    query_parameter {
      name          = {{ query_parameter.name | quote }}
      required      = {{ query_parameter.required | to_terraform_bool }}
      type          = {{ query_parameter.type | quote }}
      description   = {{ query_parameter.description | empty_to_none | quote }}
      default_value = {{ query_parameter.default_value | quote }}
      values        = [{{ query_parameter.values | quote | join(", ") }}]
      type_name     = {{ query_parameter.type_name | quote }}
{%- if query_parameter.schema_id %}
      schema_id     = azurerm_api_management_api_schema.{{ tf_api_id  }}_{{ query_parameter.schema_id | last_segment | to_terraform_id }}[0].schema_id
{%- endif %}
    }
{%- endfor %}
{# request.representation #}
{%- for representation in operation.request.representations %}
    representation {
      content_type = {{ representation.content_type | quote }}
{%- if representation.schema_id %}
      schema_id    = azurerm_api_management_api_schema.{{ tf_api_id  }}_{{ representation.schema_id | last_segment | to_terraform_id }}[0].schema_id
{%- endif %}
      type_name    = {{ representation.type_name | quote }}
{# request.representation.form_parameter #}
{%- for form_parameter in (representation.form_parameters or []) %}
      form_parameter {
        name          = {{ form_parameter.name | quote }}
        required      = {{ form_parameter.required | to_terraform_bool }}
        type          = {{ form_parameter.type | quote }}
        description   = {{ form_parameter.description | empty_to_none | quote }}
        default_value = {{ form_parameter.default_value | quote }}
        values        = [{{ form_parameter.values | quote | join(", ") }}]
        schema_id     = {{ form_parameter.schema_id | quote }}
        type_name     = {{ form_parameter.type_name | quote }}
      }
{%- endfor %}
{# request.representation.example #}
{%- for example_name, example in (representation.examples or {}).items() %}
      example {
        name          = {{ example_name | quote }}
        summary       = {{ example.summary | empty_to_none | quote }}
        description   = {{ example.description | empty_to_none | quote }}
{%- if example.value %}
        value         = {{ example.value | tojson(indent=2) | tojson }}
{%- endif %}
      }
{%- endfor %}
    }
{%- endfor %}
  }
{%- for response in operation.responses %}

  response {
    status_code = {{ response.status_code | str | quote }}
    description = {{ response.description | quote }}
{# response.header #}
{%- for header in response.headers %}
    header {
      name          = {{ header.name | quote }}
      required      = {{ header.required | to_terraform_bool }}
      type          = {{ header.type | quote }}
      description   = {{ header.description | empty_to_none | quote }}
      default_value = {{ header.default_value | quote }}
      values        = [{{ header.values | quote | join(", ") }}]
      type_name     = {{ header.type_name | quote }}
{%- if header.schema_id %}
      schema_id     = azurerm_api_management_api_schema.{{ tf_api_id  }}_{{ header.schema_id | last_segment | to_terraform_id }}[0].schema_id
{%- endif %}
    }
{%- endfor %}
{# response.representation #}
{%- for representation in response.representations %}
    representation {
      content_type = {{ representation.content_type | quote }}
{%- if representation.schema_id %}
      schema_id    = azurerm_api_management_api_schema.{{ tf_api_id  }}_{{ representation.schema_id | last_segment | to_terraform_id }}[0].schema_id
{%- endif %}
      type_name    = {{ representation.type_name | quote }}
{# response.representation.form_parameter #}
{%- for form_parameter in (representation.form_parameters or []) %}
      form_parameter {
        name          = {{ form_parameter.name | quote }}
        required      = {{ form_parameter.required | to_terraform_bool }}
        type          = {{ form_parameter.type | quote }}
        description   = {{ form_parameter.description | empty_to_none | quote }}
        default_value = {{ form_parameter.default_value | quote }}
        values        = [{{ form_parameter.values | quote | join(", ") }}]
        schema_id     = {{ form_parameter.schema_id | quote }}
        type_name     = {{ form_parameter.type_name | quote }}
      }
{%- endfor %}
{# response.representation.example #}
{%- for example_name, example in (representation.examples or {}).items() %}
      example {
        name          = {{ example_name | quote }}
        summary       = {{ example.summary | empty_to_none | quote }}
        description   = {{ example.description | empty_to_none | quote }}
{%- if example.value %}
        value         = {{ example.value | tojson | tojson }}
{%- endif %}
      }
{%- endfor %}
    }
{%- endfor %}
  }
{%- endfor %}
{# template_parameter #}
{%- for template_parameter in operation.template_parameters %}
  template_parameter {
    {# ignoring example #}
    name          = {{ template_parameter.name | quote }}
    required      = {{ template_parameter.required | to_terraform_bool }}
    type          = {{ template_parameter.type | quote }}
    description   = {{ template_parameter.description | empty_to_none | quote }}
    default_value = {{ template_parameter.default_value | quote }}
    values        = [{{ template_parameter.values | quote | join(", ") }}]
{%- if template_parameter.schema_id %}
    schema_id     = azurerm_api_management_api_schema.{{ tf_api_id  }}_{{ template_parameter.schema_id | last_segment | to_terraform_id }}[0].schema_id
{%- endif %}
    type_name     = {{ template_parameter.type_name | quote }}
  }
{%- endfor %}
{%- endif %}
}
{%- with operation_policy_path = operation_policy_paths.get(operation.id, None) %}
{%- if operation_policy_path %}

resource "azurerm_api_management_api_operation_policy" "{{ tf_api_id }}--{{ tf_operation_id }}" {
  count                = contains([{{ environments | quote | join(", ")}}], var.environment) ? 1 : 0
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  api_name            = azurerm_api_management_api.{{ tf_api_id }}[0].name
  operation_id        = azurerm_api_management_api_operation.{{ tf_api_id }}--{{ tf_operation_id }}[0].operation_id
  xml_content         = file("${path.module}/{{ operation_policy_path }}")
}
{% endif -%}
{% endwith -%}
{% endwith -%}