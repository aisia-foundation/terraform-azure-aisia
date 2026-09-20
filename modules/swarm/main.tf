###############################################################################
# AISIA — Multi-cloud Phase 4 partie 2 (sprint v6.13.16)
#
# Module Terraform Azure : déploie un cluster Docker Swarm AISIA minimal sur
# Azure Linux VMs (Standard_D2s_v3).
#
#   ┌──────────────────────────────────────────────────────────────────┐
#   │ Resource Group dédié + VNet + Subnet + NSG                       │
#   │ 1 manager VM (Standard_D2s_v3) + N workers (Standard_D2s_v3)     │
#   │ cloud-init installe Docker + initialise Swarm                    │
#   │ Worker join token publié dans Azure Key Vault (TODO v5.5.67)     │
#   └──────────────────────────────────────────────────────────────────┘
#
# Statut : SKELETON DOCUMENTÉ — pas exécuté en CI. Provisioning manuel.
#
# Usage :
#   cd infra/terraform/azure
#   az login
#   terraform init
#   terraform plan -var="image_tag=v6.13.11"
#   terraform apply
#
# Dépendances : Terraform >= 1.5, az CLI logué (ou ARM_* env vars envoyées
# par l'endpoint /admin/cloud-providers/azure-eu/test).
###############################################################################

###############################################################################
# Resource group + Networking
###############################################################################
resource "azurerm_resource_group" "aisia" {
  name     = "${var.cluster_name}-rg"
  location = var.region

  tags = {
    Project = "AISIA"
    Sprint  = "v6.13.16"
  }
}

resource "azurerm_virtual_network" "aisia" {
  name                = "${var.cluster_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.aisia.location
  resource_group_name = azurerm_resource_group.aisia.name

  tags = { Project = "AISIA" }
}

resource "azurerm_subnet" "aisia" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.aisia.name
  virtual_network_name = azurerm_virtual_network.aisia.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 1)]
}

###############################################################################
# Network Security Group (NSG) — Swarm + HTTP/HTTPS + SSH
###############################################################################
resource "azurerm_network_security_group" "aisia" {
  name                = "${var.cluster_name}-nsg"
  location            = azurerm_resource_group.aisia.location
  resource_group_name = azurerm_resource_group.aisia.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "swarm-mgmt"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["2377", "7946"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "swarm-overlay"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_ranges    = ["7946", "4789"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = { Project = "AISIA" }
}

resource "azurerm_subnet_network_security_group_association" "aisia" {
  subnet_id                 = azurerm_subnet.aisia.id
  network_security_group_id = azurerm_network_security_group.aisia.id
}

###############################################################################
# Public IPs + NICs
###############################################################################
resource "azurerm_public_ip" "manager" {
  name                = "${var.cluster_name}-manager-pip"
  location            = azurerm_resource_group.aisia.location
  resource_group_name = azurerm_resource_group.aisia.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = { Project = "AISIA" }
}

resource "azurerm_network_interface" "manager" {
  name                = "${var.cluster_name}-manager-nic"
  location            = azurerm_resource_group.aisia.location
  resource_group_name = azurerm_resource_group.aisia.name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.aisia.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.manager.id
  }

  tags = { Project = "AISIA" }
}

resource "azurerm_public_ip" "worker" {
  count               = var.node_count
  name                = "${var.cluster_name}-worker-${count.index + 1}-pip"
  location            = azurerm_resource_group.aisia.location
  resource_group_name = azurerm_resource_group.aisia.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = { Project = "AISIA" }
}

resource "azurerm_network_interface" "worker" {
  count               = var.node_count
  name                = "${var.cluster_name}-worker-${count.index + 1}-nic"
  location            = azurerm_resource_group.aisia.location
  resource_group_name = azurerm_resource_group.aisia.name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.aisia.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker[count.index].id
  }

  tags = { Project = "AISIA" }
}

###############################################################################
# cloud-init scripts
###############################################################################
locals {
  cloud_init_manager = base64encode(<<-EOT
    #cloud-config
    package_update: true
    packages:
      - docker.io
    runcmd:
      - systemctl enable --now docker
      - usermod -aG docker ${var.admin_username}
      - PRIV_IP=$(hostname -I | awk '{print $1}') && docker swarm init --advertise-addr "$PRIV_IP"
      - docker swarm join-token -q worker > /tmp/worker-token
      # AISIA image tag : ${var.image_tag}
      # TODO v5.5.67 : publier worker-token dans Azure Key Vault
  EOT
  )

  cloud_init_worker = base64encode(<<-EOT
    #cloud-config
    package_update: true
    packages:
      - docker.io
    runcmd:
      - systemctl enable --now docker
      - usermod -aG docker ${var.admin_username}
      # TODO v5.5.67 : fetch worker-token depuis Azure Key Vault puis
      # docker swarm join --token <TOKEN> ${azurerm_network_interface.manager.private_ip_address}:2377
  EOT
  )
}

###############################################################################
# Manager VM
###############################################################################
resource "azurerm_linux_virtual_machine" "manager" {
  name                  = "${var.cluster_name}-manager"
  location              = azurerm_resource_group.aisia.location
  resource_group_name   = azurerm_resource_group.aisia.name
  size                  = var.instance_flavor
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.manager.id]
  custom_data           = local.cloud_init_manager

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Role    = "swarm-manager"
    Project = "AISIA"
  }
}

###############################################################################
# Worker VMs
###############################################################################
resource "azurerm_linux_virtual_machine" "worker" {
  count                 = var.node_count
  name                  = "${var.cluster_name}-worker-${count.index + 1}"
  location              = azurerm_resource_group.aisia.location
  resource_group_name   = azurerm_resource_group.aisia.name
  size                  = var.instance_flavor
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.worker[count.index].id]
  custom_data           = local.cloud_init_worker

  depends_on = [azurerm_linux_virtual_machine.manager]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Role    = "swarm-worker"
    Project = "AISIA"
  }
}
