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
      containers = [
        {
          name   = "frontend"
          image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          cpu    = 0.5
          memory = "1Gi"
          env = [
            {
              name  = "ENVIRONMENT"
              value = "production"
            },
            {
              name  = "API_URL"
              value = "https://api.example.com"
            }
          ]
        }
      ]
    },
    "api" = {
      containers = [
        {
          name   = "api"
          image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          cpu    = 0.25
          memory = "0.5Gi"
          env = [
            {
              name  = "ENVIRONMENT"
              value = "production"
            },
            {
              name  = "DB_CONNECTION"
              value = "..."
            },
            {
              name        = "DB_PASSWORD"
              secret_name = "db-password-secret"
            }
          ]
        }
      ]
    }
  }
}
