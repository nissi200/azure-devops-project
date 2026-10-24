output "resource_group_name" {
  description = "Name of the created Resource Group"
  value       = azurerm_resource_group.devops_rg.name
}

output "vm_name" {
  description = "Name of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.devops_vm.name
}

output "public_ip_address" {
  description = "Public IP address of the deployed Azure Virtual Machine"
  value       = azurerm_public_ip.devops_public_ip.ip_address
}

output "web_application_url" {
  description = "Direct URL to access the deployed web application"
  value       = "http://${azurerm_public_ip.devops_public_ip.ip_address}"
}

output "ssh_connection_command" {
  description = "SSH command to connect to the Azure VM"
  value       = "ssh -i azure_vm_key.pem ${var.admin_username}@${azurerm_public_ip.devops_public_ip.ip_address}"
}

output "admin_username" {
  description = "Admin username for VM access"
  value       = var.admin_username
}
