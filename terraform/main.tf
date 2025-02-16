module "naming" {
  source = "Azure/naming/azurerm"
  suffix = ["cloudresume", local.environment]
}

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = local.location

  tags = local.tags
}

resource "azurerm_storage_account" "storage_account" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document     = "index.html"
    error_404_document = "index.html"
  }

  tags = local.tags
}

resource "azurerm_storage_table" "storage_table" {
  name                 = local.storage_table_name
  storage_account_name = azurerm_storage_account.storage_account.name
}

resource "azurerm_service_plan" "service_plan" {
  name                = local.app_service_plan_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  os_type  = "Linux"
  sku_name = "B1"

  tags = local.tags
}

resource "azurerm_linux_function_app" "function_app" {
  name                = local.function_app_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  service_plan_id            = azurerm_service_plan.service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key

  site_config {}

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_profile" "frontdoor_profile" {
  name                = local.frontdoor_profile_name
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "frontdoor_origin_group" {
  name                     = local.frontdoor_origin_group_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id

  health_probe {
    interval_in_seconds = 240
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 2
  }
}

resource "azurerm_cdn_frontdoor_origin" "frontdoor_origin" {
  name                           = local.frontdoor_origin_name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group.id
  enabled                        = true
  certificate_name_check_enabled = true

  origin_host_header = azurerm_storage_account.storage_account.primary_web_endpoint
  host_name          = azurerm_storage_account.storage_account.primary_web_endpoint
  http_port          = 80
  https_port         = 443
  priority           = 1
  weight             = 1000
}

resource "azurerm_cdn_frontdoor_endpoint" "frontdoor_endpoint" {
  name                     = local.frontdoor_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
}

resource "azurerm_cdn_frontdoor_rule_set" "frontdoor_rule_set" {
  name                     = local.frontdoor_rule_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
}

resource "azurerm_cdn_frontdoor_custom_domain" "frontdoor_custom_domain" {
  name                     = local.custom_domain_resource_friendly
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
  host_name                = local.custom_domain

  tls {
    certificate_type = "ManagedCertificate"
  }
}

resource "azurerm_cdn_frontdoor_route" "frontdoor_route" {
  name                          = local.frontdoor_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontdoor_origin.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.frontdoor_rule_set.id]
  enabled                       = true

  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.frontdoor_custom_domain.id]
  link_to_default_domain          = false

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "domain_association" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.frontdoor_custom_domain.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.frontdoor_route.id]
}