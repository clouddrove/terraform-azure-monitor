provider "azurerm" {
  subscription_id = "000000-11111-1223-XXX-XXXXXXXXXXXX"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  name        = "app"
  environment = "test"
}

##----------------------------------------------------------------------------- 
## Resource Group module call
## Resource group in which all resources will be deployed.
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "clouddrove/resource-group/azure"
  version     = "1.0.2"
  name        = "app-ampls"
  environment = "test"
  label_order = ["name", "environment", ]
  location    = "Canada Central"
}

##----------------------------------------------------------------------------- 
## Virtual Network module call.
##-----------------------------------------------------------------------------
module "vnet" {
  source              = "clouddrove/vnet/azure"
  version             = "1.0.4"
  name                = local.name
  environment         = local.environment
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.0.0.0/16"]
}

##----------------------------------------------------------------------------- 
## Subnet module call.
## Delegated subnet for mysql.
##-----------------------------------------------------------------------------
module "subnet" {
  source               = "clouddrove/subnet/azure"
  version              = "1.2.1"
  name                 = local.name
  environment          = local.environment
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = join("", module.vnet.vnet_name)
  #subnet
  subnet_names      = ["default"]
  subnet_prefixes   = ["10.0.1.0/24"]
  service_endpoints = ["Microsoft.Storage"]
  delegation = {
    flexibleServers_delegation = [
      {
        name    = "Microsoft.DBforMySQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    ]
  }
}

##----------------------------------------------------------------------------- 
## Log Analytics module call.
## Log analytics workspace in which storage diagnostic logs will be sent. 
##-----------------------------------------------------------------------------
module "log-analytics" {
  source                           = "clouddrove/log-analytics/azure"
  version                          = "1.1.0"
  name                             = local.name
  environment                      = local.environment
  create_log_analytics_workspace   = true
  log_analytics_workspace_sku      = "PerGB2018"
  daily_quota_gb                   = "-1"
  internet_ingestion_enabled       = true
  internet_query_enabled           = true
  diagnostic_setting_enable        = false
  resource_group_name              = module.resource_group.resource_group_name
  log_analytics_workspace_location = module.resource_group.resource_group_location
}

module "ampls" {
  providers = {
    azurerm.main_sub = azurerm,
    azurerm.dns_sub  = azurerm
  }
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



