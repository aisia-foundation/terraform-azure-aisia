###############################################################################
# terraform-azure-aisia — outputs (contrat normalisé substrat K8s AKS).
# Utiliser kube_config_raw + cluster_endpoint pour configurer le provider
# kubernetes/helm dans le root module, puis appeler terraform-aisia-cluster.
###############################################################################

output "cluster_name" {
  description = "Nom du cluster AKS."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_endpoint" {
  description = "Endpoint du control plane AKS (API server URL)."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "kube_config_raw" {
  description = "Kubeconfig brut du cluster AKS (sensible — à stocker dans un secret)."
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "client_certificate" {
  description = "Certificat client AKS (base64)."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Clé client AKS (base64)."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate AKS (base64)."
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Commande pour récupérer le kubeconfig localement via az CLI."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aisia.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "resource_group_name" {
  description = "Nom du Resource Group AKS créé par le module."
  value       = azurerm_resource_group.aisia.name
}

output "location" {
  description = "Région Azure du déploiement."
  value       = var.location
}

output "gpu_pool_enabled" {
  description = "Un node pool GPU a-t-il été provisionné ?"
  value       = var.gpu_enabled
}
