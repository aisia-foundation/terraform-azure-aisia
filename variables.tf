###############################################################################
# terraform-azure-aisia — variables d'entrée.
# Substrat AKS (Azure Kubernetes Service). Contrat normalisé v6.9.61.
#
# Auth Azure : le consumer configure `provider "azurerm" { features {} }` dans
# son root module, avec subscription_id et tenant_id dans le provider block
# (ou via ARM_SUBSCRIPTION_ID / ARM_TENANT_ID env vars). Ces credentials ne
# transitent pas par les variables du module.
###############################################################################

# ── Contrat normalisé (commun à tous les clouds × substrats) ───────────────
variable "org_id" {
  description = "Identifiant de l'organisation AISIA (tenant)."
  type        = string
}

variable "service_key" {
  description = "Brique déployée (C1..C11)."
  type        = string
}

variable "runtime_kind" {
  description = "edge | compute | compute-gpu | data | ops | security."
  type        = string
  default     = "compute"
}

variable "substrate" {
  description = "Substrat cible. Ce module provisionne le substrat 'k8s' (AKS)."
  type        = string
  default     = "k8s"
}

variable "profile" {
  description = "Profil de dimensionnement (S | M | L | XL)."
  type        = string
  default     = "S"
}

variable "node_count" {
  description = "Nombre de nœuds du pool système AKS."
  type        = number
  default     = 1
}

variable "image_registry" {
  description = "Registry des images AISIA (utilisé pour le tagging ; l'app est déployée via terraform-aisia-cluster)."
  type        = string
  default     = "registry.aisia.fr"
}

variable "image_tag" {
  description = "Tag d'image AISIA à déployer (utilisé pour le tagging Azure)."
  type        = string
  default     = "v6.9.66"
}

variable "domain" {
  description = "Domaine custom de l'org (vide = *.aisia.fr)."
  type        = string
  default     = ""
}

variable "tier" {
  description = "Offre tarifaire AISIA (saas | baas | paas)."
  type        = string
  default     = "saas"
  validation {
    condition     = contains(["saas", "baas", "paas"], var.tier)
    error_message = "tier doit etre 'saas', 'baas' ou 'paas'."
  }
}

variable "gpu_enabled" {
  description = "Provisionner un node pool GPU (Standard_NC4as_T4_v3 par défaut)."
  type        = bool
  default     = false
}

# ── Spécifiques Azure / AKS ───────────────────────────────────────────────
variable "location" {
  description = "Région Azure (francecentral par défaut pour conformité RGPD)."
  type        = string
  default     = "francecentral"
}

variable "resource_group" {
  description = "Nom du Resource Group Azure dédié (créé par le module)."
  type        = string
  default     = "aisia-aks-rg"
}

variable "cluster_name" {
  description = "Nom logique du cluster AKS (préfixe des ressources)."
  type        = string
  default     = "aisia-aks"
}

variable "vm_size" {
  description = "Taille VM Azure des nœuds AKS (Standard_D2s_v3 = 2 vCPU / 8 GB RAM)."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "k8s_version" {
  description = "Version Kubernetes AKS (null = version recommandée par Azure)."
  type        = string
  default     = null
}

variable "gpu_vm_size" {
  description = "Taille VM du pool GPU optionnel (Standard_NC4as_T4_v3 = 1x NVIDIA T4)."
  type        = string
  default     = "Standard_NC4as_T4_v3"
}
