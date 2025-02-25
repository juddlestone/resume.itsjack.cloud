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

locals {
  # Common settings for all apps
  common_settings = {
    revision_suffix = "v1"
  }

  # App-specific configurations including environment variables
  app_configs = {
    "app1" = {
      max_replicas = 10
      min_replicas = 1
      containers = [
        {
          name   = "frontend"
          image  = "myregistry.azurecr.io/frontend:latest"
          cpu    = 0.5
          memory = "1Gi"
          env = [
            {
              name  = "APP_TYPE"
              value = "frontend"
            }
          ]
        }
      ]
    },
    "app2" = {
      max_replicas = 5
      min_replicas = 1
      containers = [
        {
          name   = "api"
          image  = "myregistry.azurecr.io/api:latest"
          cpu    = 0.25
          memory = "0.5Gi"
          env = [
            {
              name  = "APP_TYPE"
              value = "api"
            }
          ]
        }
      ]
    }
  }

  # Merge common settings with app-specific configs
  container_apps = {
    for app_name, app_config in local.app_configs : app_name => merge(local.common_settings, app_config)
  }
}
