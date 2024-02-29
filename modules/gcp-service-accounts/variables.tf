variable "gcp_project" {
  type        = string
  description = "The ID of the GCP project"
}

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
      k8s_sa_name = optional(string) # The name of the top-level key for this service account will be used as the name if this is not provided.
    })
  )
  default = {}
}
