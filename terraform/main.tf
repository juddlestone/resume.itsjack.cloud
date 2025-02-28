data "azurerm_client_config" "current" {
}

module "naming" {
  source = "Azure/naming/azurerm"
  suffix = [local.application_name, local.environment]
}

resource "time_static" "this" {}

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = local.location

  tags = local.tags
}

# Budget
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

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.log_analytics_workspace_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

# Container App Environment
module "cae" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.2.1"

  name                = local.container_app_environment_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  log_analytics_workspace_customer_id        = azurerm_log_analytics_workspace.law.workspace_id
  log_analytics_workspace_primary_shared_key = azurerm_log_analytics_workspace.law.primary_shared_key

  zone_redundancy_enabled = false

  storages = {
    "visitor-data" = {
      account_name = azurerm_storage_account.this.name
      share_name   = azurerm_storage_share.this.name
      access_key   = azurerm_storage_account.this.primary_access_key
      access_mode  = "ReadWrite"
    }
  }

  tags = local.tags
}


# Container App
module "container_app" {
  for_each = local.container_apps
  source   = "Azure/avm-res-app-containerapp/azurerm"
  version  = "0.3.0"

  name                                  = "ca-${each.key}-${local.application_name}-${local.environment}"
  resource_group_name                   = azurerm_resource_group.this.name
  container_app_environment_resource_id = module.cae.resource_id
  revision_mode                         = "Single"
  workload_profile_name                 = "Consumption"

  template = each.value.template
  ingress  = each.value.ingress

  custom_domains = each.value.custom_domains

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this[each.key].id]
  }

  registries = {
    identity = azurerm_user_assigned_identity.this[each.key].resource_id
    server   = "acrmanacr.azurecr.io"
  }

  tags = local.tags
}

# Container App - User Assigned Identity
resource "azurerm_user_assigned_identity" "this" {
  for_each            = local.container_apps
  name                = "uai-${each.key}-${local.application_name}-${local.environment}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}


# Container App - ACR Pull
resource "azurerm_role_assignment" "acrpull" {
  for_each             = local.container_apps
  scope                = local.container_registry_resource_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this[each.key].principal_id
}

# Storage Account
resource "azurerm_storage_account" "this" {
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Storage Container
resource "azurerm_storage_container" "certifications" {
  name                  = "certifications"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "container"
}

# Upload files to Storage Container
resource "azurerm_storage_blob" "certifications" {
  for_each               = fileset("${path.root}/blobs/certifications", "*")
  name                   = each.value
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.certifications.name
  type                   = "Block"
  source                 = "${path.root}/blobs/certifications/${each.value}"
  content_type           = "image/png"
}

# Storage File
resource "azurerm_storage_share" "this" {
  name               = "visitor-data"
  storage_account_id = azurerm_storage_account.this.id
  quota              = "1"
}
