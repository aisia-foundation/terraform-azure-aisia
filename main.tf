###############################################################################
# terraform-azure-aisia — substrat AKS (Azure Kubernetes Service).
#
#   ┌──────────────────────────────────────────────────────────────────────┐
#   │ Resource Group dédié                                                  │
#   │ azurerm_kubernetes_cluster (AKS) :                                   │
#   │   - default_node_pool (système) VirtualMachineScaleSets              │
#   │   - identity SystemAssigned (managed identity, pas de SP à gérer)    │
#   │   - CNI Azure, LB Standard                                           │
#   │   - pool GPU optionnel (taint nvidia.com/gpu=present:NoSchedule)     │
#   └──────────────────────────────────────────────────────────────────────┘
#
# Usage : chaîner avec terraform-aisia-cluster pour déployer la stack AISIA.
# Le consumer configure `provider "azurerm" { features {} }` dans son root module.
# Outputs `kube_config_raw` et `cluster_endpoint` alimentent les providers
# kubernetes/helm du root module → appel module terraform-aisia-cluster.
###############################################################################

locals {
  name = "aisia-${var.org_id}-${var.service_key}"

  tags = {
    Project   = "AISIA"
    Org       = var.org_id
    Service   = var.service_key
    Tier      = var.tier
    image_tag = var.image_tag
    ManagedBy = "terraform"
  }
}

###############################################################################
# Resource Group
###############################################################################
resource "azurerm_resource_group" "aisia" {
  name     = var.resource_group
  location = var.location
  tags     = local.tags
}

###############################################################################
# Cluster AKS managé
###############################################################################
resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.name
  location            = azurerm_resource_group.aisia.location
  resource_group_name = azurerm_resource_group.aisia.name
  dns_prefix          = replace(local.name, "_", "-")
  kubernetes_version  = var.k8s_version

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.vm_size
    # upgrade_settings required by provider >= 4.0
    upgrade_settings {
      max_surge = "10%"
    }
    node_labels = {
      aisia_pool = "system"
      aisia_org  = var.org_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = local.tags
}

###############################################################################
# Pool GPU optionnel (inférence C4)
###############################################################################
resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  count                 = var.gpu_enabled ? 1 : 0
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.gpu_vm_size
  node_count            = 1

  node_labels = {
    aisia_pool = "gpu"
    aisia_org  = var.org_id
  }

  node_taints = ["nvidia.com/gpu=present:NoSchedule"]

  tags = local.tags
}
