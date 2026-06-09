variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for the project"
  type        = string
  default     = "polandcentral"
}

variable "resource_group_name" {
  description = "Main resource group name"
  type        = string
  default     = "rg-acs-project-itolic"
}

variable "common_tags" {
  description = "Common tags required by the project"
  type        = map(string)
  default = {
    university = "Algebra"
    student    = "student@algebra.hr"
  }
}

variable "admin_ip_cidr" {
  description = "Public IP address allowed to access Key Vault, in CIDR format"
  type        = string
  sensitive   = true
}

variable "app_gateway_backend_ip" {
  description = "Private IP address of the AKS internal LoadBalancer service"
  type        = string
}