terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.64, < 6"
    }
  }
}


locals {
  # This variable manipulation is necessary because each SA is described by the map:
  # { <service_name> : roles = ["role1", "role2"...] } and for_each requires a map
  # of type { <unique_key>: "some_string" }. As a result the SA map has to be coerced to:
  # { <service_name>_<role> : "role" }
  gcp_sa_roles = flatten([
    for name, value in var.gcp_service_accounts : [
      for role in value.roles : {
        name = name
        role = role
      }
    ]
  ])
  workload_id_sa_roles = flatten([
    for name, value in var.k8s_workload_service_accounts : [
      for role in value.roles : {
        name = name
        role = role
      }
    ]
  ])
  workloads_by_namespace = flatten([
    for name, value in var.k8s_workload_service_accounts : [
      for namespace in value.namespaces : {
        name          = name
        namespace     = namespace
        create_k8s_sa = lookup(value, "create_k8s_sa")
        k8s_sa_name   = value.k8s_sa_name != null ? value.k8s_sa_name : name
      }
    ]
  ])
}

# Traditional GCP Service Accounts

resource "google_service_account" "gcp_service_account" {
  for_each     = var.gcp_service_accounts
  account_id   = "${each.key}-sa"
  project      = var.gcp_project
  display_name = "Service account for ${title(each.key)}"
}

resource "google_project_iam_member" "gcp_service_account_iam_member" {
  for_each = {
    for sa_role in local.gcp_sa_roles : "${sa_role.name}_${sa_role.role}" => {
      name = sa_role.name
      role = sa_role.role
    }
  }
  project = var.gcp_project
  role    = "roles/${each.value.role}"
  member  = google_service_account.gcp_service_account[each.value.name].member
}

resource "google_service_account_key" "gcp_service_account_key" {
  for_each           = { for name, sa in var.gcp_service_accounts : name => sa if sa.create_key }
  service_account_id = google_service_account.gcp_service_account[each.key].name
}

resource "google_service_account_iam_binding" "workload_identity_users" {
  for_each = {
    for name, value in var.gcp_service_accounts : name => value.workload_identity_users if length(value.workload_identity_users) > 0
  }
  service_account_id = google_service_account.gcp_service_account[each.key].id
  role               = "roles/iam.workloadIdentityUser"
  members            = each.value
}

# Service Accounts with Kubernetes Workload Identity

resource "google_service_account" "workload_service_account" {
  for_each     = var.k8s_workload_service_accounts
  account_id   = "${each.key}-sa"
  project      = var.gcp_project
  display_name = "Service account for ${title(each.key)}"
}

resource "google_project_iam_member" "workload_service_account_iam_member" {
  for_each = {
    for sa_role in local.workload_id_sa_roles : "${sa_role.name}_${sa_role.role}" => {
      name = sa_role.name
      role = sa_role.role
    }
  }
  project = var.gcp_project
  role    = "roles/${each.value.role}"
  member  = google_service_account.workload_service_account[each.value.name].member
}

# Ref: https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to
resource "google_service_account_iam_member" "workload_identity_sa_binding" {
  for_each = {
    for workload in local.workloads_by_namespace : "${workload.name}_${workload.namespace}" => {
      name        = workload.name
      k8s_sa_name = workload.k8s_sa_name
      namespace   = workload.namespace
    }
  }
  service_account_id = google_service_account.workload_service_account[each.value.name].id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project}.svc.id.goog[${each.value.namespace}/${each.value.k8s_sa_name}]"
}

resource "google_service_account_key" "workload_gcp_service_account_key" {
  for_each           = { for name, workload in var.k8s_workload_service_accounts : name => workload if workload.create_key }
  service_account_id = google_service_account.workload_service_account[each.key].name
}
