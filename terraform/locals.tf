locals {
  application_name                = "cloudresume"
  custom_domain_resource_friendly = replace(var.custom_domain, ".", "-")
  environment                     = var.environment
  location                        = var.location

  container_registry_resource_id = var.container_registry_resource_id

  container_app_environment_name = module.naming.container_app_environment.name
  log_analytics_workspace_name   = module.naming.log_analytics_workspace.name
  resource_group_name            = module.naming.resource_group.name
  user_assigned_identity_name    = module.naming.user_assigned_identity.name

  budget_name       = "budget-${module.naming.resource_group.name}"
  budget_start_date = formatdate("YYYY-MM-01'T'hh:mm:ssZ", time_static.this.rfc3339)
  budget_end_date   = timeadd(time_static.this.rfc3339, "26280h")

  tags = {
    "Environment"  = upper(local.environment)
    "Criticality"  = "Low"
    "ServiceName"  = "CloudResume"
    "ServiceOwner" = "jack@itsjack.cloud"
  }
}



# Containers
locals {
  container_apps = {
    "frontend" = {
      custom_domain    = var.custom_domain
      image            = "mcr.microsoft.com/azuredocs/aks-helloworld:v1"
      port             = 80
      external_enabled = true
      environment_variables = {
        "COUNTER_CONTAINER_HOSTNAME" = "ca-counter-${local.application_name}-${local.environment}"
      }
    }

    # "counter" = {
    #   image            = "mcr.microsoft.com/azuredocs/aks-helloworld:v1"
    #   port             = 80
    #   external_enabled = false
    #   environment_variables = {
    #     "AZURE_STORAGE_ACCOUNT_NAME" = module.naming.storage_account.name_unique
    #     "STORAGE_TABLE_NAME"         = "visitors"
    #   }

    #   secrets = {
    #     "AZURE_STORAGE_ACCOUNT_KEY" = module.key_vault.secrets["storage-account-key"].value
    #   }
    # }
  }
}
