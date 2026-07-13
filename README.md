<!-- GENERATED:09_publications:start -->
<!--
  GÉNÉRÉ — ne pas éditer à la main.
  Source: scripts/generate/09_publications.py
  Régénérer: python3 scripts/aisia.py regen
  Gate deploy: python3 scripts/release/deploy.py <ver> --mode docs
-->

# terraform-azure-aisia

> **v6.12.25** — module registry — bootstrap Azure + substrat AISIA

## Cœur d'AISIA (identité produit)

AISIA est le **chef d'orchestre IA local-first** : une requête entre, le meilleur modèle (local ou cloud) exécute, la réponse sort traçable et gouvernée.

**Fonction première** : orchestrer chaque requête IA en **local-first** (Ollama sur cluster)
puis cloud si nécessaire — via `BanditRouter`, pas un simple reverse-proxy.

**Différenciation** : orchestration local-first — pas un proxy LLM stateless.

| vs proxy LLM | AISIA |
|--------------|-------|
| 1 provider fixe | **87** providers + **58** modèles locaux |
| Stateless | Qdrant + audit AI Act + multi-tenant |
| SaaS opaque | Déployable Swarm/K8s — **v6.12.25** LIVE |

Documentation : [README racine](../../../../README.md) ·
[Product Identity](../../../../specification/03-Project-State/Product-Identity-AISIA.md)

```mermaid
flowchart LR
  App[Application] --> AISIA[AISIA orchestration]
  AISIA --> Local[Ollama local]
  AISIA --> Cloud[Providers cloud]
```


---
<!-- GENERATED:09_publications:end -->

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
  image_tag   = "v6.12.25"

  location       = "francecentral"
  resource_group = "aisia-acme-rg"
  node_count     = 2
}

# L2 — déploiement AISIA sur AKS
module "aisia_app" {
  source  = "app.terraform.io/AISIA/aisia-cluster/kubernetes"
  version = "~> 1.0"

  image_tag = "v6.12.25"
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
| `image_tag` | Tag d'image AISIA (pour tagging Azure) | `string` | `"v6.12.25"` | non |
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

## Référence des variables & sorties (auto-générée)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

<!-- TF-MODULE-DOCS:09_publications -->
## Documentation AISIA

- **Documentation produit** : [aisia.fr/docs](https://aisia.fr/docs)
- **Référence API** : [api.aisia.fr/docs](https://api.aisia.fr/docs)
- **Provider Terraform** : [aisia-foundation/aisia](https://registry.terraform.io/providers/aisia-foundation/aisia/latest/docs)
- **Guide d'implémentation** : [getting-started](https://registry.terraform.io/providers/aisia-foundation/aisia/latest/docs/guides/getting-started)
- **Version LIVE** : **v6.12.25**
