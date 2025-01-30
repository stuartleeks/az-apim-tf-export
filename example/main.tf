locals {
  apim_name = "apim-${var.resource_suffix}-${var.environment}"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#
# This file contains the API Management service
# It also contains the backends, named values etc, i.e. the sub-resources that are environment-specific
# APIs and products are handled in the generated module
#

resource "azurerm_api_management" "apim" {
  name                = local.apim_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "test publisher"
  publisher_email     = "test@contoso.com"

  sku_name = "Developer_1"

  min_api_version = "2019-12-01"


  lifecycle {
    prevent_destroy = true
  }

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_log_analytics_workspace" "common" {
  name                = "log-${var.resource_suffix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "common" {
  name                = "appi-${var.resource_suffix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.common.id
}


resource "azurerm_api_management_logger" "apim_logger" {
  name                = "apim-logger"
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.resource_group_name
  resource_id         = azurerm_application_insights.common.id

  application_insights {
    instrumentation_key = azurerm_application_insights.common.instrumentation_key
  }
}

resource "azurerm_api_management_diagnostic" "app_insights_diagnostics" {
  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = azurerm_api_management.apim.name
  api_management_logger_id = azurerm_api_management_logger.apim_logger.id

  sampling_percentage = 100.0
  always_log_errors   = true
  verbosity           = "verbose" #possible value are verbose, error, information
}


####################################################################################
## This section is commented out to enable the initial deployment
## of the dev environment.
## Once you have created the dev environment and exported the APIs and Products
## the `apim-generated` folder will exist and you can uncomment this section

# # Use the "apim-generated" module to create APIs and products
# # This is generated from an APIM instance
# module "apim_generated" {
#   source              = "./apim-generated"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = var.location
#   api_management_name = azurerm_api_management.apim.name
#   environment = var.environment
# }

####################################################################################