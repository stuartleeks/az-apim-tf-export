variable "location" {
  type        = string
  description = "The Azure location in which the deployment is happening"
  default     = "francecentral"
}


variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which the resources are deployed"
}


variable "resource_suffix"{
  type        = string
  description = "The suffix to be added to the resources for uniqueness"
}

variable "environment" {
  type        = string
  description = "The environment for which the resources are being deployed"
}
