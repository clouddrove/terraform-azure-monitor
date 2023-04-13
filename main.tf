
module "labels" {

  source  = "clouddrove/labels/azure"
  version = "1.0.0"

  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
}

resource "azurerm_monitor_private_link_scope" "main" {
  count = var.enabled && var.ampls_enabled  && var.diff_sub == false ? 1 : 0 
  name                = format("%s-ampls", module.labels.id)
  resource_group_name = var.resource_group_name
  tags = module.labels.tags
}

resource "azurerm_monitor_private_link_scoped_service" "main" {
  count = var.enabled && var.ampls_enabled && var.enable_private_endpoint  && var.diff_sub == false ? length(var.linked_resource_ids) : 0 
  name                = format("%s-amplsservice-%s", module.labels.id, count.index + 1) 
  resource_group_name = var.resource_group_name
  scope_name          = join("", azurerm_monitor_private_link_scope.main.*.name)
  linked_resource_id  =  element(var.linked_resource_ids, count.index)
}

locals {
  private_dns_zones_names = var.private_dns_zones_names
  diff_sub = true
}

resource "azurerm_private_dns_zone" "main" {
  count            = var.enable_private_endpoint && var.diff_sub == false ?  length(var.private_dns_zones_names) : 0
  name                = element(var.private_dns_zones_names, count.index)
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_endpoint" "this" {
  count  = var.enable_private_endpoint && var.diff_sub == false ? 1 : 0 
  name                = format("%s-ampls-pe", module.labels.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = azurerm_private_dns_zone.main.*.id
  }

  private_service_connection {
    name                           = format("%s-ampls-psc", module.labels.id )
    is_manual_connection           = false
    private_connection_resource_id = var.azurerm_monitor_private_link_scope_id == null ? join("",azurerm_monitor_private_link_scope.main.*.id) : var.azurerm_monitor_private_link_scope_id
    subresource_names              = ["azuremonitor"]
  }
}

provider "azurerm" {
  alias = "peer"
  features {}
  subscription_id = var.alias_sub
}

resource "azurerm_private_dns_zone" "diff_sub" {
  provider            = azurerm.peer
  count            = var.enable_private_endpoint && var.diff_sub == true ?  length(var.private_dns_zones_names) : 0
  name                = element(var.private_dns_zones_names, count.index)
  resource_group_name = var.diff_sub_resource_group_name
}

resource "azurerm_private_endpoint" "diff_sub_pe" {
  provider            = azurerm.peer
  count               = var.enable_private_endpoint && var.diff_sub ? 1 : 0 
  name                = format("%s-ampls-pe", module.labels.id)
  location            = var.diff_sub_location
  resource_group_name = var.diff_sub_resource_group_name
  subnet_id           = var.subnet_id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = azurerm_private_dns_zone.diff_sub.*.id
  }

  private_service_connection {
    name                           = format("%s-ampls-psc", module.labels.id )
    is_manual_connection           = false
    private_connection_resource_id = var.azurerm_monitor_private_link_scope_id == null ? join("",azurerm_monitor_private_link_scope.main.*.id) : var.azurerm_monitor_private_link_scope_id
    subresource_names              = ["azuremonitor"]
  }
}