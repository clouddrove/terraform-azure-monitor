terraform {
  required_version = ">= 1.6.6"
}

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">=3.0.0"
      configuration_aliases = [azurerm.main_sub, azurerm.dns_sub]
    }
  }
}