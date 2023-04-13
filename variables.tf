#Module      : LABEL
#Description : Terraform label module variables.

variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "repository" {
  type        = string
  default     = "https://github.com/clouddrove/terraform-azure-subnet.git"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "attributes" {
  type        = list(any)
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `organization`, `environment`, `name` and `attributes`."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

variable "managedby" {
  type        = string
  default     = "hello@clouddrove.com"
  description = "ManagedBy, eg 'CloudDrove'."
}

variable "enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any resources."
  default     = true
}

variable "resource_group_name" {
  default     = ""
  description = "A container that holds related resources for an Azure solution"
}

variable "location" {
  type        = string
  default     = ""
  description = "Location where resource should be created."
}

variable "ampls_enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating ampls resource."
  default     = true
}

variable "linked_resource_ids" {
  type        = list(string)
  default     = [""]
  description = "(Required) The name of the Azure Monitor Private Link Scoped Service. Changing this forces a new resource to be created."
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "(Required) The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created."
}

variable "subscription_id" {
  type        = string
  default     = ""
  description = "(Optional) Specifies the ID of the subscription. If this argument is omitted, the subscription ID of the current Azure Resource Manager provider is used."
}

variable "private_dns_zones_names" {
  type        = list(string)
  default     = [""]
  description = "The name of the private dns zones from which private dns will be created for AMPLS"
}

variable "enable_private_endpoint" {
  type        = bool
  default     = true
  description = "enable or disable private endpoint to storage account"
}

variable "azurerm_monitor_private_link_scope_id" {
  type        = string
  default     = null
  description = "The id  of the monitor private link scope from which private dns will be created for it"
}

variable "diff_sub" {
  # To be set true when hosted DNS zone is in different subnscription.
  type        = bool
  default     = false
  description = "Flag to tell whether dns zone is in different sub or not."
}

variable "alias_sub" {
  # To be set when you are using a DNS zone from different subscription.
  type        = string
  default     = null
  description = "Different subscription id for local provider(id of diff sub in which DNS zone is present)."
}

variable "diff_sub_resource_group_name" {
  default     = ""
  description = "A container that holds related different subscription resources for an Azure solution"
}

variable "diff_sub_location" {
  type        = string
  default     = ""
  description = "Location where different subscription resource should be created."
}