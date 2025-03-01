locals {
  application_name                = "cloudresume"
  custom_domain_resource_friendly = replace(var.custom_domain, ".", "-")
  environment                     = var.environment
  location                        = var.location


  container_registry_resource_id = var.container_registry_resource_id
  container_registry_url         = "acrmanacr.azurecr.io"

  app_service_plan_name      = module.naming.app_service_plan.name
  function_app_name          = module.naming.function_app.name
  function_app_identity_name = "uai-${module.naming.function_app.name}"
  resource_group_name        = module.naming.resource_group.name
  storage_account_name       = module.naming.storage_account.name_unique
  storage_table_name         = replace(module.naming.storage_table.name, "-", "")


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
