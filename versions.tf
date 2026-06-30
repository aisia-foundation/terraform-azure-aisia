###############################################################################
# terraform-azure-aisia — contraintes providers (module publiable, sans bloc provider).
# Le consumer configure `provider "azurerm" { features {} ... }` dans son root module.
###############################################################################
terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
