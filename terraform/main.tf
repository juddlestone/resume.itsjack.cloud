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
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.3.0"

  name                                  = module.naming.container_app.name
  resource_group_name                   = azurerm_resource_group.this.name
  container_app_environment_resource_id = module.cae.resource_id
  revision_mode                         = "Single"
  workload_profile_name                 = "Consumption"

  template = {
    max_replicas = 1
    min_replicas = 0
    containers = [
      {
        name   = module.naming.container_app.name
        image  = "acrmanacr.azurecr.io/resume/frontend:${var.frontend_version}"
        cpu    = 0.25
        memory = "0.5Gi"
        env = [
          {
            name  = "BLOB_ENDPOINT"
            value = "${azurerm_storage_account.this.primary_blob_endpoint}certifications/"
          }
        ]
      }
    ],
    volume_mounts = [
      {
        name       = "visitor-data"
        mount_path = "/visitor-data"
      }
    ],
    volumes = [
      {
        name         = "visitor-data"
        storage_name = "visitor-data"
        storage_type = "AzureFile"
      }
    ]
  }

  ingress = {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 5000
    transport                  = "http"
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }

  custom_domains = {
    domain = {
      name                     = var.custom_domain
      certificate_binding_type = "SniEnabled"
    }
  }

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }

  registries = [
    {
      identity = azurerm_user_assigned_identity.this.id
      server   = local.container_registry_url
    }
  ]

  tags = local.tags
}

# Container App - User Assigned Identity
resource "azurerm_user_assigned_identity" "this" {
  name                = local.user_assigned_identity_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}


# Container App - ACR Pull
resource "azurerm_role_assignment" "acrpull" {
  scope                = local.container_registry_resource_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
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
