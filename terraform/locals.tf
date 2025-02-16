locals {
  custom_domain                   = "resume.itsjack.cloud"
  custom_domain_resource_friendly = replace(local.custom_domain, ".", "-")
  environment                     = "dev"
  location                        = "uksouth"

  app_service_plan_name = module.naming.app_service_plan.value
  function_app_name     = module.naming.function_app.value
  resource_group_name   = module.naming.resource_group.value
  storage_account_name  = module.naming.storage_account.unique
  storage_table_name    = module.naming.storage_table.value

  frontdoor_profile_name      = module.naming.frontdoor.value
  frontdoor_origin_group_name = "${custom_domain_resource_friendly}-origin-group"
  frontdoor_origin_name       = "${custom_domain_resource_friendly}-origin"
  frontdoor_endpoint_name     = "${custom_domain_resource_friendly}-endpoint"
  frontdoor_rule_name         = "${custom_domain_resource_friendly}-rule-set"
  frontdoor_route_name        = "${customer_domain_resource_friendly}-route"

  tags = {
    "Environment"        = upper(local.environment)
    "Criticality"        = "Low"
    "WorkloadName"       = "Cloud Resume"
    "DataClassification" = "Public"
  }
}