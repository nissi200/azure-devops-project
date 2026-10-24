# 1. Resource Group
resource "azurerm_resource_group" "devops_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Project     = "DevOps-CI-CD"
    Environment = "Demonstration"
    ManagedBy   = "Terraform"
  }
}

# 2. Virtual Network
resource "azurerm_virtual_network" "devops_vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  address_space       = var.vnet_address_space

  tags = azurerm_resource_group.devops_rg.tags
}

# 3. Subnet
resource "azurerm_subnet" "devops_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

# 4. Public IP
resource "azurerm_public_ip" "devops_public_ip" {
  name                = "pip-${var.vm_name}"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.devops_rg.tags
}

# 5. Network Security Group (NSG) with SSH and HTTP rules
resource "azurerm_network_security_group" "devops_nsg" {
  name                = "nsg-${var.vm_name}"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.devops_rg.tags
}

# 6. Network Interface (NIC)
resource "azurerm_network_interface" "devops_nic" {
  name                = "nic-${var.vm_name}"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.devops_public_ip.id
  }

  tags = azurerm_resource_group.devops_rg.tags
}

# Associate NSG with Network Interface
resource "azurerm_network_interface_security_group_association" "devops_nic_nsg" {
  network_interface_id      = azurerm_network_interface.devops_nic.id
  network_security_group_id = azurerm_network_security_group.devops_nsg.id
}

# Generate SSH Key pair automatically if an existing key is not specified
resource "tls_private_key" "vm_ssh_key" {
  count     = var.ssh_public_key_path == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save generated private key locally so the student/Jenkins can SSH into the machine
resource "local_file" "private_key" {
  count           = var.ssh_public_key_path == "" ? 1 : 0
  content         = tls_private_key.vm_ssh_key[0].private_key_pem
  filename        = "${path.module}/azure_vm_key.pem"
  file_permission = "0600"
}

# 7. Azure Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "devops_vm" {
  name                = var.vm_name
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.devops_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key_path != "" ? file(var.ssh_public_key_path) : tls_private_key.vm_ssh_key[0].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = azurerm_resource_group.devops_rg.tags
}
