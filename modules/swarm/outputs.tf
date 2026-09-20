###############################################################################
# AISIA Terraform Azure — outputs (sprint v6.13.16)
###############################################################################

# ── Contrat de sortie normalisé (commun substrat swarm) ────────────────────
output "region" {
  description = "Région Azure du déploiement."
  value       = var.region
}

output "node_count" {
  description = "Nombre de workers provisionnés (hors manager)."
  value       = var.node_count
}

output "manager_ip" {
  description = "IP publique du manager Swarm (entry point Traefik)"
  value       = azurerm_public_ip.manager.ip_address
}

output "manager_private_ip" {
  description = "IP privée du manager (advertise-addr Swarm)"
  value       = azurerm_network_interface.manager.private_ip_address
}

output "worker_ips" {
  description = "Liste des IPs publiques des workers"
  value       = [for w in azurerm_public_ip.worker : w.ip_address]
}

output "worker_private_ips" {
  description = "Liste des IPs privées des workers"
  value       = [for n in azurerm_network_interface.worker : n.private_ip_address]
}

output "resource_group_name" {
  description = "Nom du Resource Group Azure dédié AISIA"
  value       = azurerm_resource_group.aisia.name
}

output "vnet_id" {
  description = "ID du VNet dédié"
  value       = azurerm_virtual_network.aisia.id
}

output "swarm_join_token_path" {
  description = <<-EOT
    Chemin du token worker dans le manager :
      ssh <admin_username>@<manager_ip> 'sudo cat /tmp/worker-token'
    NOTE : v5.5.67 publiera ce token dans Azure Key Vault automatiquement.
  EOT
  value       = "/tmp/worker-token"
}

output "next_steps" {
  description = "Étapes manuelles à exécuter après terraform apply"
  value       = <<-EOT
    1. Récupérer le worker token :
       ssh ${var.admin_username}@${azurerm_public_ip.manager.ip_address} 'sudo cat /tmp/worker-token'

    2. Joindre chaque worker manuellement (auto-join arrive v5.5.67) :
       ssh ${var.admin_username}@<worker_ip> "docker swarm join --token <TOKEN> ${azurerm_network_interface.manager.private_ip_address}:2377"

    3. Déployer la stack AISIA :
       scp deploy/stack-aisia.yml ${var.admin_username}@${azurerm_public_ip.manager.ip_address}:/tmp/
       ssh ${var.admin_username}@${azurerm_public_ip.manager.ip_address} 'docker stack deploy -c /tmp/stack-aisia.yml aisia'
  EOT
}
