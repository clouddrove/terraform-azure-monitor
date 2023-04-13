provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "resource_group" {
  source  = "clouddrove/resource-group/azure"
  version = "1.0.2"

  name        = "app-ampls"
  environment = "test"
  label_order = ["name", "environment", ]
  location    = "Canada Central"
}

module "vnet" {
  source  = "clouddrove/vnet/azure"
  version = "1.0.1"

  name                = "app"
  environment         = "test"
  label_order         = ["name", "environment"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_space       = "10.30.0.0/16"
}

module "subnet" {
  source  = "clouddrove/subnet/azure"
  version = "1.0.2"

  name                 = "app"
  environment          = "test"
  label_order          = ["name", "environment"]
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = join("", module.vnet.vnet_name)

  #subnet
  subnet_names    = ["subnet1"]
  subnet_prefixes = ["10.30.1.0/24"]

  # route_table
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

module "log-analytics" {
  source                           = "clouddrove/log-analytics/azure"
  version                          = "1.0.1"
  name                             = "app"
  environment                      = "test"
  label_order                      = ["name", "environment"]
  create_log_analytics_workspace   = true
  log_analytics_workspace_sku      = "PerGB2018"
  resource_group_name              = module.resource_group.resource_group_name
  log_analytics_workspace_location = module.resource_group.resource_group_location
}

module "ampls" {
  source      = "../../"
  name        = "app"
  environment = "test"
  label_order = ["name", "environment"]

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  linked_resource_ids = [module.log-analytics.workspace_id]
  subnet_id           = module.subnet.default_subnet_id[0]
  private_dns_zones_names = [
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.blob.core.windows.net",
    "privatelink.monitor.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.oms.opinsights.azure.com",
  ]
}

data "azurerm_subscription" "current" {
}


provider "azurerm" {
  alias = "other"
  features {}
  subscription_id = "82d2a91c-9e70-40c9-8a97-3c1e353b2a80"
}

data "azurerm_resource_group" "other_rg" {
  provider = azurerm.other
  name     = "test"
}

module "ampls_diff_subs" {
  source      = "../../"
  name        = "app-1"
  environment = "test-1"
  label_order = ["name", "environment"]

  diff_sub_resource_group_name = data.azurerm_resource_group.other_rg.name
  diff_sub_location            = module.resource_group.resource_group_location
  subnet_id                    = "/subscriptions/82d2a91c-9e70-40c9-8a97-3c1e353b2a80/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/default"

  azurerm_monitor_private_link_scope_id = "/subscriptions/cbaecd6a-2e7c-4524-bef7-eb0d2fba93db/resourceGroups/app-ampls-test-resource-group/providers/microsoft.insights/privateLinkScopes/app-test-ampls"
  diff_sub                              = true
  alias_sub                             = "82d2a91c-9e70-40c9-8a97-3c1e353b2a80"
  private_dns_zones_names = [
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.blob.core.windows.net",
    "privatelink.monitor.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.oms.opinsights.azure.com",
  ]
}

