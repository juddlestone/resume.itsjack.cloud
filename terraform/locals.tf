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
  container_apps = {
    "frontend" = {
      template = {
        revision_suffix = "v1"
        max_replicas    = 1
        min_replicas    = 0
        containers = [
          {
            name   = "ca-frontend-${local.application_name}-${local.environment}"
            image  = "mcr.microsoft.com/k8se/quickstart:latest"
            cpu    = 0.25
            memory = "0.5Gi"
            env = [
              {
                name  = "APP_TYPE"
                value = "frontend"
              }
            ]
          }
        ]
      },
      ingress = {
        allow_insecure_connections = false
        external_enabled           = true
        target_port                = 80
        transport                  = "http"
        traffic_weight = [{
          latest_revision = true
          percentage      = 100
        }]
      }
    },

    "backend" = {
      template = {
        revision_suffix = "v1"
        max_replicas    = 1
        min_replicas    = 0
        containers = [
          {
            name   = "ca-backend-${local.application_name}-${local.environment}"
            image  = "mcr.microsoft.com/k8se/quickstart:latest"
            cpu    = 0.25
            memory = "0.5Gi"
            env = [
              {
                name  = "APP_TYPE"
                value = "backend"
              }
            ]
          }
        ],
        volume_mounts = [
          {
            name = "visitor-data"
            path = "/visitor-data"
          }
        ],
        volumes = [
          {
            name         = "visitor-data"
            storage_name = "visitor-data"
            storage_type = "AzureFiles"
          }
        ]
      },
      ingress = {
        allow_insecure_connections = false
        external_enabled           = false
        target_port                = 80
        transport                  = "http"
        traffic_weight = [{
          latest_revision = true
          percentage      = 100
        }]
      }
    }
  }
}
