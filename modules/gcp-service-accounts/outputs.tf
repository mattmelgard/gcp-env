output "gcp_service_account_emails" {
  description = "The service account emails for any GCP service accounts created by this module."
  value = tomap({
    for name, sa in google_service_account.gcp_service_account : name => sa.email
  })
}

output "k8s_workload_service_account_emails" {
  description = "The service account emails for any Kubernetes workload service accounts created by this module."
  value = tomap({
    for name, sa in google_service_account.workload_service_account : name => sa.email
  })
}

output "gcp_service_account_keys" {
  description = "The service account keys (if any) created by this module."
  value = merge(
    tomap({
      for name, sa_key in google_service_account_key.gcp_service_account_key : name => sa_key.private_key
    }),
    tomap({
      for name, sa_key in google_service_account_key.workload_gcp_service_account_key : name => sa_key.private_key
    })
  )
  sensitive = true
}
