# Changelog — terraform-azure-aisia

Format : [Keep a Changelog](https://keepachangelog.com/) · Versioning : SemVer.

## [6.12.78] — 2026-08-04

### Changed
- Sync `image_tag` default -> `v6.12.78` (release AISIA v6.12.78 LIVE). Rattrape aussi le
  saut `v6.12.77` (VERSION + image_tag bumpés en v6.12.77 par le commit `ad31e4ac8` sans
  entrée CHANGELOG, jamais publié au registry). Aucun changement fonctionnel des
  resources/variables/outputs (patch de synchronisation de version).

## [6.12.76] — 2026-08-02

### Changed
- Sync `image_tag` default -> `v6.12.76` (release AISIA v6.12.76 LIVE). Aucun changement
  fonctionnel des resources/variables/outputs (patch de synchronisation de version).

## [1.0.0] — 2026-06-29

### Added
- Module initial publiable (HCP private registry) : substrat AKS (Azure Kubernetes Service).
- **Cluster** : `azurerm_kubernetes_cluster` (SystemAssigned identity, node pool système
  `VirtualMachineScaleSets`, CNI Azure, LB Standard).
- **GPU** : node pool optionnel `Standard_NC4as_T4_v3` (taint `nvidia.com/gpu=present:NoSchedule`)
  activé par `gpu_enabled=true`.
- **RGPD** : défaut `location=francecentral` pour conformité RGPD.
- **Parité dual-substrate** : pendant K8s du module Azure/Swarm interne. Contrat normalisé v6.9.61.
- Outputs normalisés : `cluster_name`, `cluster_endpoint` (sensitive), `kube_config_raw`
  (sensitive), `kubeconfig_command`, `resource_group_name`.
- Chaîner avec `terraform-aisia-cluster` pour déployer la stack AISIA sur le substrat AKS.
- README (Inputs/Outputs/Usage), LICENSE MPL-2.0, `versions.tf` (TF >= 1.5, azurerm ~> 4.0).
- `examples/basic` : usage minimal validable (`tofu validate`).
