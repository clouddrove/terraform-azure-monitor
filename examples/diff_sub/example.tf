provider "azurerm" {
  subscription_id = "000000-11111-1223-XXX-XXXXXXXXXXXX"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias = "other"
  features {}
  subscription_id = "100000-11111-1223-XXX-XXXXXXXXXXXX"
}

data "azurerm_resource_group" "other_rg" {
  provider = azurerm.other
  name     = "test"
}

module "ampls_diff_subs" {
  providers = {
    azurerm.main_sub = azurerm,
    azurerm.dns_sub  = azurerm.other
  }
  source      = "../../"
  name        = "app-1"
  environment = "test-1"
  label_order = ["name", "environment"]

  diff_sub_resource_group_name = data.azurerm_resource_group.other_rg.name
  diff_sub_location            = module.resource_group.resource_group_location
  subnet_id                    = "****"

  azurerm_monitor_private_link_scope_id = "**"
  diff_sub                              = true
  alias_sub                             = "***"
  private_dns_zones_names = [
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.blob.core.windows.net",
    "privatelink.monitor.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.oms.opinsights.azure.com",
  ]
}