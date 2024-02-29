resource "google_service_account" "main_cluster_sa" {
  project      = var.gcp_project_id
  account_id   = local.main_cluster_service_account_name
  display_name = "The service account for the main cluster in this environment"
}

resource "google_container_cluster" "main_cluster" {
  project                  = var.gcp_project_id
  name                     = local.main_cluster_name
  location                 = var.gcp_region
  network                  = google_compute_network.main.self_link
  subnetwork               = google_compute_subnetwork.main_cluster.self_link
  enable_shielded_nodes    = var.main_cluster_features.enable_shielded_nodes
  initial_node_count       = 1
  remove_default_node_pool = true
  deletion_protection      = local.deletion_protection_enabled

  # Accept known production-ready upgrades for GKE by default
  # https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels
  release_channel {
    channel = "REGULAR"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # VPC Native cluster configuration
  # https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips
  ip_allocation_policy {
    cluster_secondary_range_name  = local.main_cluster_pod_subnet_name
    services_secondary_range_name = local.main_cluster_service_subnet_name
  }

  # Use a private cluster configuration for security hardening purposes, but enable a public endpoint with
  # restricted access for authorized networks (see master authorized networks configuration below). This allows
  # external clients to connect if they have been allow-listed. This is convenient for specific purposes such
  # as when deploying to the cluster from CI/CD platforms.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.main_cluster_master_cidr
  }

  # Allow only specific CIDR blocks access to the public endpoint of the cluster
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = concat(var.main_cluster_master_authorized_networks, local.main_cluster_default_master_authorized_networks)
      content {
        display_name = cidr_blocks.value.display_name
        cidr_block   = cidr_blocks.value.cidr_block
      }
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "05:00" # 1:00am EST
    }
  }

  security_posture_config {
    mode               = var.main_cluster_features.enable_workload_scanning ? "BASIC" : "DISABLED"
    vulnerability_mode = var.main_cluster_features.enable_workload_scanning ? "VULNERABILITY_BASIC" : "VULNERABILITY_DISABLED"
  }

  addons_config {
    config_connector_config {
      enabled = var.main_cluster_features.enable_config_connector
    }
    gcp_filestore_csi_driver_config {
      enabled = var.main_cluster_features.enable_filestore_csi_driver
    }
  }
}

resource "google_project_iam_member" "service_account-roles" {
  for_each = local.main_cluster_sa_default_roles
  project  = var.gcp_project_id
  role     = each.value
  member   = google_service_account.main_cluster_sa.member
}

resource "google_container_node_pool" "node_pool" {
  for_each = var.main_cluster_node_pools
  name     = each.key
  project  = var.gcp_project_id
  location = var.gcp_region
  cluster  = google_container_cluster.main_cluster.name
  node_locations = each.value.zones != null ? each.value.zones : [
    for zone in var.main_cluster_default_node_availability_zones : "${var.gcp_region}-${zone}"
  ]

  # Start with the minimum node count, but enable autoscaling
  initial_node_count = each.value.min_node_count
  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  # Allow automatic repair and upgrade of node pools
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Configure each compute instance (node) in the pool
  node_config {
    machine_type    = each.value.machine_type
    labels          = each.value.labels
    image_type      = "COS_CONTAINERD"
    tags            = concat(local.required_node_tags, each.value.node_tags)
    service_account = google_service_account.main_cluster_sa.email
    preemptible     = lookup(each.value, "preemptible", false)
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taints.key
        value  = taints.value
        effect = taints.effect
      }
    }
    metadata = {
      block-project-ssh-keys   = "true"
      disable-legacy-endpoints = "true"
    }
  }
}

# GKE Config Connector Service Account + Role + Workload Identity Binding
# Ref: https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall

resource "google_service_account" "k8s_config_connector_sa" {
  count        = var.main_cluster_features.enable_config_connector ? 1 : 0
  account_id   = "k8s-config-connector-sa"
  project      = var.gcp_project_id
  display_name = "Service account for the GKE Config Connector addon"
}

resource "google_project_iam_member" "k8s_config_connector_role" {
  for_each = var.main_cluster_features.enable_config_connector ? toset(var.config_connector_project_roles) : []
  project  = var.gcp_project_id
  role     = each.value
  member   = google_service_account.k8s_config_connector_sa[0].member
}

resource "google_service_account_iam_member" "workload_identity_sa_binding" {
  count              = var.main_cluster_features.enable_config_connector ? 1 : 0
  service_account_id = google_service_account.k8s_config_connector_sa[0].id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[cnrm-system/cnrm-controller-manager]"
}
