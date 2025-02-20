data "azurerm_client_config" "current" {
}

module "naming" {
  source = "Azure/naming/azurerm"
  suffix = [local.application_name, local.environment]
}


resource "time_static" "this" {}

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

resource "azurerm_user_assigned_identity" "this" {
  name                = local.user_assigned_identity_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_container_app" "this" {
  for_each                     = local.container_apps
  name                         = "ca-${each.value.name}-${local.application_name}-${local.environment}"
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"

  template {
    container {
      name   = "ca-${each.value.name}-${local.application_name}-${local.environment}"
      image  = each.value.image
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    target_port = each.value.port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
