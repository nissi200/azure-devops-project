variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
  default     = "rg-devops-webapp"
}

variable "location" {
  type        = string
  description = "Azure Region for provisioning resources"
  default     = "eastus"
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
  default     = "vnet-devops"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network"
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  type        = string
  description = "Name of the Subnet"
  default     = "snet-devops-web"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefix for the Subnet"
  default     = ["10.0.1.0/24"]
}

variable "vm_name" {
  type        = string
  description = "Name of the Azure Virtual Machine"
  default     = "vm-devops-server"
}

variable "vm_size" {
  type        = string
  description = "Size of the Azure Virtual Machine"
  default     = "Standard_B1s" # Cost-effective burstable tier for student accounts
}

variable "admin_username" {
  type        = string
  description = "Admin username for the Azure Virtual Machine"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Optional path to existing public SSH key. If empty, an SSH key pair will be generated automatically."
  default     = ""
}
