###############################################################################
# Exemple minimal — terraform-azure-aisia (substrat AKS)
#
# Prérequis : credentials Azure.
#   az login
#   export ARM_SUBSCRIPTION_ID=<subscription-id>
#   export ARM_TENANT_ID=<tenant-id>
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

###############################################################################
# L1 — substrat AKS (1 nœud système, profil S)
###############################################################################
module "aisia_aks" {
  # Registre HCP privé (nécessite credentials) :
  #   source  = "app.terraform.io/AISIA/aisia/azure"
  #   version = "~> 1.0"
  source = "../../"

  org_id      = "acme"
  service_key = "C1"
  image_tag   = "v6.12.45"
  tier        = "saas"

  location       = "francecentral"
  resource_group = "aisia-acme-rg"
  cluster_name   = "aisia-acme-aks"
  node_count     = 1
  vm_size        = "Standard_D2s_v3"
}

###############################################################################
# L2 — déploiement AISIA (dans votre root module après cet example) :
#
# provider "kubernetes" {
#   host                   = module.aisia_aks.cluster_endpoint
#   client_certificate     = base64decode(module.aisia_aks.client_certificate)
#   client_key             = base64decode(module.aisia_aks.client_key)
#   cluster_ca_certificate = base64decode(module.aisia_aks.cluster_ca_certificate)
# }
#
# module "aisia_app" {
#   source  = "app.terraform.io/AISIA/aisia-cluster/kubernetes"
#   version = "~> 1.0"
#   image_tag = "v6.12.45"
#   tier      = "saas"
#   domain    = "acme.aisia.fr"
# }
###############################################################################

output "cluster_name" {
  value = module.aisia_aks.cluster_name
}

output "kubeconfig_command" {
  value = module.aisia_aks.kubeconfig_command
}

output "resource_group" {
  value = module.aisia_aks.resource_group_name
}
