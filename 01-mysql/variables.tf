# ================================================================================
# Input Variables
# ================================================================================

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy resources into"
  type        = string
}

variable "region" {
  description = "OCI region for deployment"
  type        = string
  default     = "us-ashburn-1"
}
