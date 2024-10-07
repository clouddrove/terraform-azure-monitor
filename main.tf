
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
  provider            = azurerm.main_sub
  count               = var.enabled && var.ampls_enabled && var.diff_sub == false ? 1 : 0
  name                = format("%s-ampls", module.labels.id)
  resource_group_name = var.resource_group_name
  tags                = module.labels.tags
}

resource "azurerm_monitor_private_link_scoped_service" "main" {
  provider            = azurerm.main_sub
  count               = var.enabled && var.ampls_enabled && var.enable_private_endpoint && var.diff_sub == false ? length(var.linked_resource_ids) : 0
  name                = format("%s-amplsservice-%s", module.labels.id, count.index + 1)
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.main[0].name
  linked_resource_id  = element(var.linked_resource_ids, count.index)
}

resource "azurerm_private_dns_zone" "main" {
  provider            = azurerm.main_sub
  count               = var.enable_private_endpoint && var.diff_sub == false ? length(var.private_dns_zones_names) : 0
  name                = element(var.private_dns_zones_names, count.index)
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_endpoint" "this" {
  provider            = azurerm.main_sub
  count               = var.enable_private_endpoint && var.diff_sub == false ? 1 : 0
  name                = format("%s-ampls-pe", module.labels.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.main[0].id]
  }

  private_service_connection {
    name                           = format("%s-ampls-psc", module.labels.id)
    is_manual_connection           = false
    private_connection_resource_id = var.azurerm_monitor_private_link_scope_id == null ? azurerm_monitor_private_link_scope.main[0].id : var.azurerm_monitor_private_link_scope_id
    subresource_names              = ["azuremonitor"]
  }
}

resource "azurerm_private_dns_zone" "diff_sub" {
  provider            = azurerm.dns_sub
  count               = var.enable_private_endpoint && var.diff_sub == true ? length(var.private_dns_zones_names) : 0
  name                = element(var.private_dns_zones_names, count.index)
  resource_group_name = var.diff_sub_resource_group_name
}

resource "azurerm_private_endpoint" "diff_sub_pe" {
  provider            = azurerm.dns_sub
  count               = var.enable_private_endpoint && var.diff_sub ? 1 : 0
  name                = format("%s-ampls-pe", module.labels.id)
  location            = var.diff_sub_location
  resource_group_name = var.diff_sub_resource_group_name
  subnet_id           = var.subnet_id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = azurerm_private_dns_zone.diff_sub[0].id
  }

  private_service_connection {
    name                           = format("%s-ampls-psc", module.labels.id)
    is_manual_connection           = false
    private_connection_resource_id = var.azurerm_monitor_private_link_scope_id == null ? join("", azurerm_monitor_private_link_scope.main[0].id) : var.azurerm_monitor_private_link_scope_id
    subresource_names              = ["azuremonitor"]
  }
}
