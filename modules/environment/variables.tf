########################
# Module Configuration #
########################

# NOTE: If the project was created using this module, the env_name would also be used to generate the project ID, but it is
# not due to the contraints of the exercise.
variable "env_name" {
  description = "The name of the environment. NOTE: This may be used to prefix or name certain resources."
  type        = string
}

variable "env_type" {
  description = "The type of environment to use. This sets certain defaults for resources, security, access etc..."
  type        = string
  validation {
    condition     = contains(["production", "staging", "development"], var.env_type)
    error_message = "Valid values for env_type are: 'production', 'staging', and 'development'"
  }
}

variable "env_region" {
  description = "The region (US/EU) where this environment should be hosted."
  type        = string
  default     = "US"
  validation {
    condition     = contains(["US", "EU"], var.env_region)
    error_message = "Valid values for env_type are: 'EU', 'US'"
  }
}

#####################
# GCP Configuration #
#####################

variable "gcp_project_id" {
  description = "The ID of the GCP project ID to use when provisioning the environment."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to use for this environment."
  type        = string
  default     = "us-central1"
}

variable "gcp_services" {
  description = "Additional GCP service APIs to enable on this environment's GCP project if any are needed."
  type        = list(string)
  default     = []
}

##############################
# Main Cluster Configuration #
##############################

variable "main_cluster_subnet_cidr" {
  description = "The CIDR range to assign to the cluster and its nodes for the main GKE cluster in this environment."
  type        = string
  default     = "10.10.0.0/20"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.main_cluster_subnet_cidr))
    error_message = "CIDR block must be in the format x.x.x.x/<prefix>"
  }
}

variable "main_cluster_pod_cidr" {
  description = "The secondary subnet CIDR range to assign to cluster pods for the main GKE cluster in this environment."
  type        = string
  default     = "10.12.0.0/14"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.main_cluster_pod_cidr))
    error_message = "CIDR block must be in the format x.x.x.x/<prefix>"
  }
}

variable "main_cluster_services_cidr" {
  description = "The secondary subnet CIDR range to assign to cluster services for the main GKE cluster in this environment."
  type        = string
  default     = "10.16.0.0/14"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.main_cluster_services_cidr))
    error_message = "CIDR block must be in the format x.x.x.x/<prefix>"
  }
}
