# Azure Naming Module
# Ensures all resources names are aligned with recommended naming conventions
module "naming" {
  source = "Azure/naming/azurerm"
  suffix = [local.application_name, local.environment]
}

# Time Static
# This is used to determine the start and end dates for the budget
resource "time_static" "this" {}

# Resource Group
# Where all resources will be created
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name
  location = local.location

  tags = local.tags
}

# Budget
# Budget on the resource group to ensure I keep an eye on costs
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

resource "azurerm_static_web_app" "this" {
  name                = module.naming.static_web_app.name
  resource_group_name = azurerm_resource_group.this.name
  location            = "westeurope"
}

# Log Analytics Workspace
# Used to collect logs from the container app
resource "azurerm_log_analytics_workspace" "law" {
  name                = module.naming.log_analytics_workspace.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

# Container App Environment
# Use the AVM module to create a container app environment
module "cae" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.2.1"

  name                    = module.naming.container_app_environment.name
  resource_group_name     = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  zone_redundancy_enabled = false

  log_analytics_workspace_customer_id        = azurerm_log_analytics_workspace.law.workspace_id
  log_analytics_workspace_primary_shared_key = azurerm_log_analytics_workspace.law.primary_shared_key

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
# Use the AVM module to create a container app
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
        image  = local.container_image
        cpu    = 0.25
        memory = "0.5Gi"
        env = [
          {
            # This is the endpoint to the storage account
            # It is used to access the certification pictures, keeping docker image small
            name  = "BLOB_ENDPOINT"
            value = local.blob_endpoint
          }
        ]
        volume_mounts = [
          {
            # This mounts an Azure File Share to the container
            # It is used to store visitor data
            name = "visitor-data"
            path = "/visitor-data"
          }
        ]
      }
    ],

    volumes = [
      {
        # This is the Azure File Share that associated with the container app environment
        name         = "visitor-data"
        storage_name = "visitor-data"
        storage_type = "AzureFile"
      }
    ]
  }

  ingress = {
    # External allowed
    # Flask app is running on port 5000
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 5000
    transport                  = "http"

    # Even though it is a single revision, this is needed.
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }

  custom_domains = {
    # Custom domain for the container app
    domain = {
      name                     = var.custom_domain
      certificate_binding_type = "SniEnabled"
    }
  }

  managed_identities = {
    # This is the user assigned identity that is used to access the ACR
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }

  registries = [
    {
      # This is the ACR that contains the container image
      identity = azurerm_user_assigned_identity.this.id
      server   = local.container_registry_url
    }
  ]
  tags = local.tags
}

# Container App - User Assigned Identity
# This is used to access the ACR
resource "azurerm_user_assigned_identity" "this" {
  name                = module.naming.user_assigned_identity.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

# Container App - ACR Pull
# This is used to allow the container app to pull images from the ACR
resource "azurerm_role_assignment" "acrpull" {
  scope                = local.container_registry_resource_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

# Storage Account
# Used to store the certification pictures and visitor data
resource "azurerm_storage_account" "this" {
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Storage Container
# Used to store the certification pictures
resource "azurerm_storage_container" "certifications" {
  name                  = "certifications"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "container"
}

# Upload files to Storage Container
# Upload the certification pictures to the storage container
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
# Used to store visitor data
resource "azurerm_storage_share" "this" {
  name               = "visitor-data"
  storage_account_id = azurerm_storage_account.this.id
  quota              = "1"
}
