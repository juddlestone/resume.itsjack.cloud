variable "custom_domain" {
  description = "The custom domain to use for the CDN"
  type        = string
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "location" {
  description = "The location to deploy to"
  type        = string
}

variable "container_registry_resource_id" {
  description = "The ID of the container registry to use"
  type        = string
}
