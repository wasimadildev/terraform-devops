variable "location" {
  description = "Azure region"
  type        = string
  default     = "Malaysia West"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-terraform-lab"
}

variable "vm_name" {
  description = "Virtual machine name"
  type        = string
  default     = "vm-terraform-lab"
}

variable "admin_username" {
  description = "Linux VM administrator username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}