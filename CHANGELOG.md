# Changelog — terraform-azure-aisia

Format : [Keep a Changelog](https://keepachangelog.com/) · Versioning : SemVer.

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
