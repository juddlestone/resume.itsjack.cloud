data "azurerm_client_config" "current" {
}

module "naming" {
  source = "Azure/naming/azurerm"
  suffix = ["cloudresume", local.environment]
}


resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location

  tags = local.tags
}

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = local.budget_name
  resource_group_id = azurerm_resource_group.this.id
  amount            = 5

  time_period {
    start_date = local.budget_start_date
    end_date   = local.budget_end_date
  }

  notification {
    operator       = "GreaterThan"
    threshold      = 75
    threshold_type = "Actual"
    contact_roles  = ["Owner"]
  }
}

resource "azurerm_container_app_environment" "this" {
  name                       = local.container_app_environment_name
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  logs_destination           = "log-analytics"

  tags = local.tags

}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
