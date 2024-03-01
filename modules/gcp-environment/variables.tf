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

variable "enable_manual_nat_ip" {
  description = <<-EOT
    Enables manual NAT IP allocation when provisioning the environment's NAT gateway.
    This is used as a way to provide a stable IP address to applications within the cluster when calling out to external services.
  EOT
  default     = false
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

#####################################
# GCP Service Account Configuration #
#####################################

variable "gcp_service_accounts" {
  description = "The list of traditional GCP service accounts to create and their associated IAM roles."
  type = map(object({
    roles                   = set(string)
    create_key              = optional(bool, false)
    workload_identity_users = optional(list(string), [])
  }))
  default = {}
}

variable "k8s_workload_service_accounts" {
  description = <<-EOT
    The list of k8s workloads to add service accounts for and their associated IAM roles.
    Workload identity will be assigned to a service account bearing the same name and namespace as the workload.
  EOT
  type = map(
    object({
      roles       = set(string)
      namespaces  = set(string)
      create_key  = optional(bool, false)
      k8s_sa_name = optional(string) # This will be set to the K8s SA name when it doesn't match the GCP SA name
    })
  )
  default = {}
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
    error_message = "CIDR block must be in the format x.x.x.x/<some_network_prefix>"
  }
}

variable "main_cluster_pod_cidr" {
  description = "The secondary subnet CIDR range to assign to cluster pods for the main GKE cluster in this environment."
  type        = string
  default     = "10.12.0.0/14"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.main_cluster_pod_cidr))
    error_message = "CIDR block must be in the format x.x.x.x/<some_network_prefix>"
  }
}

variable "main_cluster_services_cidr" {
  description = "The secondary subnet CIDR range to assign to cluster services for the main GKE cluster in this environment."
  type        = string
  default     = "10.16.0.0/14"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.main_cluster_services_cidr))
    error_message = "CIDR block must be in the format x.x.x.x/<some_network_prefix>"
  }
}

variable "main_cluster_master_cidr" {
  description = "The CIDR range assigned to the GCP hosted control plane for the main GKE cluster in this environment."
  type        = string
  default     = "10.20.0.0/28"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/28", var.main_cluster_master_cidr))
    error_message = "Cluster master CIDR block must be in the format x.x.x.x/28"
  }
}

variable "main_cluster_master_authorized_networks" {
  description = "A list of CIDR blocks to include in the main cluster's master authorized networks."
  type = list(object({
    display_name = string
    cidr_block   = string
  }))
  default = []
}

variable "main_cluster_authorized_control_plane_ports" {
  description = <<-EOT
    TCP ports that the main cluster's control plane is authorized to reach cluster nodes on. This is often
    needed for cluster services that need to have bi-directional communication with the control plane, such as a
    service mesh or ingress controller. See https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#add_firewall_rules
    for more info.
  EOT
  type        = list(number)
  default     = []
}

variable "main_cluster_default_node_availability_zones" {
  description = "The list of availability zones (from the broader network region) to deploy the main cluster's node-pools within."
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "config_connector_project_roles" {
  description = "The project roles to assign the GKE Config Connector GCP service account. Defaults to the Editor and Service Account Admin roles."
  type        = list(string)
  default     = ["roles/editor", "roles/iam.serviceAccountAdmin"]
}

variable "main_cluster_node_pools" {
  description = "A map (where the key is name) of node pools to create in the cluster."
  type = map(object({
    min_node_count = number
    max_node_count = number
    machine_type   = string
    labels         = optional(map(string))
    node_tags      = optional(list(string), [])
    zones          = optional(list(string))
    preemptible    = optional(bool)
    taints = optional(
      list(object({
        key    = optional(string)
        value  = optional(string)
        effect = optional(string)
      })), []
    )
  }))
  default = {}
}

variable "main_cluster_features" {
  description = "Enable or disable features on the main cluster for this environment."
  type = object({
    enable_workload_scanning    = optional(bool, true)
    enable_shielded_nodes       = optional(bool, true)
    enable_config_connector     = optional(bool, false)
    enable_filestore_csi_driver = optional(bool, false)
  })
  default = {}
}
