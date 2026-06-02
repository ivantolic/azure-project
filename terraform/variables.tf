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