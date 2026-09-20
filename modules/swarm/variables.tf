###############################################################################
# AISIA Terraform Azure — variables
#
# Contrat NORMALISÉ v6.13.16 : les 13 variables communes ci-dessous sont
# identiques (noms + types + defaults cloud-agnostiques) à tous les clouds ×
# substrats (référence : infra/terraform/gcp/{k8s,swarm}). Les defaults
# spécifiques au cloud (region, instance_flavor, substrate) sont adaptés à Azure.
# Le worker T7 (app/deploy) génère ces variables via CloudProvider._tfvars.
###############################################################################

# ── Contrat normalisé (commun à tous les clouds) ───────────────────────────
variable "org_id" {
  description = "Identifiant de l'organisation AISIA (tenant)."
  type        = string
}

variable "service_key" {
  description = "Brique déployée (C1..C11, cf. aisia_deployable_services)."
  type        = string
}

variable "runtime_kind" {
  description = "edge|compute|compute-gpu|data|ops|security."
  type        = string
  default     = "compute"
}

variable "substrate" {
  description = "Substrat cible (k8s|swarm). Ici : swarm."
  type        = string
  default     = "swarm"
}

variable "profile" {
  description = "Profil de dimensionnement (S|M|L|XL)."
  type        = string
  default     = "S"
}

variable "region" {
  description = "Région Azure (préférer francecentral pour conformité RGPD)."
  type        = string
  default     = "francecentral"
}

variable "node_count" {
  description = "Nombre de nœuds workers (le manager est en plus)."
  type        = number
  default     = 1
}

variable "instance_flavor" {
  description = "Taille VM Azure des nœuds (Standard_D2s_v3 = 2 vCPU / 8 GB RAM)."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "image_registry" {
  description = "Registry des images AISIA."
  type        = string
  default     = "registry.aisia.fr"
}

variable "image_tag" {
  description = "Tag d'image AISIA à déployer."
  type        = string
  default     = "v6.13.16"
}

variable "domain" {
  description = "Domaine custom de l'org (vide = *.aisia.fr)."
  type        = string
  default     = ""
}

variable "tier" {
  description = "Offre (saas|baas|paas)."
  type        = string
  default     = "saas"
}

variable "gpu_enabled" {
  description = "Provisionner un pool GPU (runtime compute-gpu / inférence C4)."
  type        = bool
  default     = false
}

# ── Spécifiques Azure ──────────────────────────────────────────────────────
variable "subscription_id" {
  description = "ID de la souscription Azure cible."
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID Azure AD."
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR du VNet dédié (par défaut 10.43.0.0/16)."
  type        = string
  default     = "10.43.0.0/16"
}

variable "cluster_name" {
  description = "Nom logique du cluster (préfixe des ressources)."
  type        = string
  default     = "aisia-azure"
}

variable "admin_username" {
  description = "Nom de l'utilisateur admin SSH."
  type        = string
  default     = "aisia"
}

variable "ssh_public_key" {
  description = "Clé publique SSH (contenu OpenSSH du fichier id_rsa.pub)."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDRs autorisés à se connecter en SSH (TODO prod : IP fixe admin)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
