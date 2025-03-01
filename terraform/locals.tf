locals {
  application_name = "cloudresume"
  environment      = var.environment
  location         = var.location

  blob_endpoint = "${azurerm_storage_account.this.primary_blob_endpoint}certifications/"

  budget_name       = "budget-${module.naming.resource_group.name}"
  budget_start_date = formatdate("YYYY-MM-01'T'hh:mm:ssZ", time_static.this.rfc3339)
  budget_end_date   = timeadd(time_static.this.rfc3339, "26280h")

  container_image                = "acrmanacr.azurecr.io/resume/frontend:${var.frontend_version}"
  container_registry_resource_id = var.container_registry_resource_id
  container_registry_url         = "acrmanacr.azurecr.io"

  tags = {
    "Environment"  = upper(local.environment)
    "Criticality"  = "Low"
    "ServiceName"  = "CloudResume"
    "ServiceOwner" = "jack@itsjack.cloud"
  }
}
