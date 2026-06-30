# terraform-azure-aisia

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-terraform-azure-aisia-7B42BC?logo=terraform)](https://registry.terraform.io/modules/aisia-foundation/aisia/azure/latest) [![License: MPL-2.0](https://img.shields.io/badge/License-MPL--2.0-brightgreen.svg)](LICENSE)

Module Terraform publié sur le registry HCP privé AISIA + public `aisia-foundation` sur registry.terraform.io.

Provisionne un substrat **Azure Kubernetes Service (AKS)** (L1) pour héberger la plateforme AISIA.
L'application AISIA est ensuite déployée via le module
[terraform-aisia-cluster](../terraform-aisia-cluster/) qui consomme les outputs `cluster_endpoint`
et `kube_config_raw` de ce module.

**Version** : 1.0.0 — Voir [CHANGELOG](CHANGELOG.md)

## Architecture

```
Azure Resource Group
  └─ AKS Cluster (SystemAssigned identity, CNI Azure, LB Standard)
       ├─ Node pool "system" (VirtualMachineScaleSets, Standard_D2s_v3 par défaut)
       └─ Node pool "gpu" (Standard_NC4as_T4_v3, optionnel — gpu_enabled=true)
```

Région par défaut : `francecentral` (conformité RGPD).

## Usage

```hcl
provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = module.aisia_aks.cluster_endpoint
  client_certificate     = base64decode(module.aisia_aks.client_certificate)
  client_key             = base64decode(module.aisia_aks.client_key)
  cluster_ca_certificate = base64decode(module.aisia_aks.cluster_ca_certificate)
}

# L1 — substrat AKS
module "aisia_aks" {
  source  = "app.terraform.io/AISIA/aisia/azure"
  version = "~> 1.0"

  org_id      = "acme"
  service_key = "C1"
  image_tag   = "v6.9.61"

  location       = "francecentral"
  resource_group = "aisia-acme-rg"
  node_count     = 2
}

# L2 — déploiement AISIA sur AKS
module "aisia_app" {
  source  = "app.terraform.io/AISIA/aisia-cluster/kubernetes"
  version = "~> 1.0"

  image_tag = "v6.9.61"
  tier      = "saas"
  domain    = "acme.aisia.fr"
}
```

## Inputs

| Nom | Description | Type | Défaut | Requis |
|-----|-------------|------|--------|--------|
| `org_id` | Identifiant de l'organisation AISIA (tenant) | `string` | — | oui |
| `service_key` | Brique déployée (C1..C11) | `string` | — | oui |
| `runtime_kind` | edge \| compute \| compute-gpu \| data \| ops \| security | `string` | `"compute"` | non |
| `substrate` | Substrat cible (ce module = k8s) | `string` | `"k8s"` | non |
| `profile` | Profil de dimensionnement (S \| M \| L \| XL) | `string` | `"S"` | non |
| `node_count` | Nombre de nœuds du pool système AKS | `number` | `1` | non |
| `image_registry` | Registry des images AISIA | `string` | `"registry.aisia.fr"` | non |
| `image_tag` | Tag d'image AISIA (pour tagging Azure) | `string` | `"v6.9.61"` | non |
| `domain` | Domaine custom (vide = *.aisia.fr) | `string` | `""` | non |
| `tier` | Offre tarifaire (saas \| baas \| paas) | `string` | `"saas"` | non |
| `gpu_enabled` | Provisionner un node pool GPU (Standard_NC4as_T4_v3) | `bool` | `false` | non |
| `location` | Région Azure (francecentral = RGPD) | `string` | `"francecentral"` | non |
| `resource_group` | Nom du Resource Group Azure créé | `string` | `"aisia-aks-rg"` | non |
| `cluster_name` | Préfixe du cluster AKS | `string` | `"aisia-aks"` | non |
| `vm_size` | Taille VM nœuds AKS (Standard_D2s_v3 = 2 vCPU / 8 GB) | `string` | `"Standard_D2s_v3"` | non |
| `k8s_version` | Version Kubernetes AKS (null = recommandée Azure) | `string` | `null` | non |
| `gpu_vm_size` | Taille VM pool GPU optionnel | `string` | `"Standard_NC4as_T4_v3"` | non |

## Outputs

| Nom | Description | Sensible |
|-----|-------------|----------|
| `cluster_name` | Nom du cluster AKS | non |
| `cluster_endpoint` | Endpoint control plane AKS (API server URL) | oui |
| `kube_config_raw` | Kubeconfig brut AKS | oui |
| `client_certificate` | Certificat client AKS (base64) | oui |
| `client_key` | Clé client AKS (base64) | oui |
| `cluster_ca_certificate` | CA certificate AKS (base64) | oui |
| `kubeconfig_command` | Commande `az aks get-credentials ...` | non |
| `resource_group_name` | Nom du Resource Group créé | non |
| `location` | Région Azure du déploiement | non |
| `gpu_pool_enabled` | Node pool GPU provisionné ? | non |

## Prérequis

- OpenTofu >= 1.5 ou Terraform >= 1.5
- Provider `hashicorp/azurerm ~> 4.0`
- `az login` ou variables ARM_* d'environnement
- `provider "kubernetes"` configuré dans le root module avec les outputs sensibles
- Module `terraform-aisia-cluster ~> 1.0` pour déployer l'application

## Licence

[Mozilla Public License 2.0](LICENSE) — Copyright (c) 2026 AISIA (Sébastien Lambert).
