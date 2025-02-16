locals {
  custom_domain                   = "resume.itsjack.cloud"
  custom_domain_resource_friendly = replace(local.custom_domain, ".", "-")
  environment                     = "dev"
  location                        = "uksouth"

  app_service_plan_name = module.naming.app_service_plan.name
  function_app_name     = module.naming.function_app.name
  resource_group_name   = module.naming.resource_group.name
  storage_account_name  = module.naming.storage_account.name_unique
  storage_table_name    = "stt-resume-visitor-count"

  frontdoor_profile_name      = module.naming.frontdoor.name
  frontdoor_origin_group_name = "${local.custom_domain_resource_friendly}-origin-group"
  frontdoor_origin_name       = "${local.custom_domain_resource_friendly}-origin"
  frontdoor_endpoint_name     = "${local.custom_domain_resource_friendly}-endpoint"
  frontdoor_rule_name         = replace("${local.custom_domain_resource_friendly}ruleset", "-", "")
  frontdoor_route_name        = "${local.custom_domain_resource_friendly}-route"

  tags = {
    "Environment"        = upper(local.environment)
    "Criticality"        = "Low"
    "WorkloadName"       = "CloudResume"
    "DataClassification" = "Public"
  }
}