locals {
  application_name                = "cloudresume"
  custom_domain                   = var.custom_domain
  custom_domain_resource_friendly = replace(local.custom_domain, ".", "-")
  environment                     = var.environment
  location                        = var.location

  user_assigned_identity_name    = module.naming.user_assigned_identity.name
  container_app_environment_name = module.naming.container_app_environment.name
  resource_group_name            = module.naming.resource_group.name
  log_analytics_workspace_name   = module.naming.log_analytics_workspace.name

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


# Container Information
locals {
  container_apps = {
    "frontend" = {
      custom_domain    = local.custom_domain
      image            = "mcr.microsoft.com/azuredocs/aks-helloworld:v1"
      port             = 80
      external_enabled = true
    }

    "counter" = {
      image            = "mcr.microsoft.com/azuredocs/aks-helloworld:v1"
      port             = 80
      external_enabled = false
    }
  }
}
