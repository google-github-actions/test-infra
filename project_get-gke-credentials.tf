# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "get-gke-credentials" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "get-gke-credentials"
  repo_description  = "A GitHub Action that configure authentication to a GKE cluster."
  repo_homepage_url = "https://cloud.google.com/gke"
  repo_topics = concat([
    "gke",
    "google-kubernetes-engine",
    "kubernetes",
  ], local.common_topics)

  repo_variables = {
    "PUBLIC_CLUSTER_NAME"      = google_container_cluster.get-gke-credentials-public.name
    "PUBLIC_CLUSTER_LOCATION"  = google_container_cluster.get-gke-credentials-public.location
    "PRIVATE_CLUSTER_NAME"     = google_container_cluster.get-gke-credentials-private.name
    "PRIVATE_CLUSTER_LOCATION" = google_container_cluster.get-gke-credentials-private.location
  }

  depends_on = [
    google_project_service.services,
  ]
}

# Grant the custom service account permissions
resource "google_project_iam_member" "get-gke-credentials" {
  for_each = toset([
    # For listing clusters
    "roles/container.viewer",

    # For private clusters: https://cloud.google.com/anthos/multicluster-management/gateway/setup#grant_iam_roles_to_users
    "roles/gkehub.gatewayReader",
    "roles/gkehub.viewer",
  ])

  project = data.google_project.project.project_id
  role    = each.value
  member  = "serviceAccount:${module.get-gke-credentials.service_account_email}"
}

# Public GKE cluster
resource "google_compute_subnetwork" "get-gke-credentials-public" {
  name          = "get-gke-credentials-public"
  ip_cidr_range = "10.0.0.0/17"
  region        = "us-central1"
  network       = google_compute_network.network.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "get-gke-credentials-public-pods"
    ip_cidr_range = "192.168.0.0/18"
  }

  secondary_ip_range {
    range_name    = "get-gke-credentials-public-services"
    ip_cidr_range = "192.168.64.0/18"
  }
}

resource "google_container_cluster" "get-gke-credentials-public" {
  name     = "get-gke-credentials-public"
  location = google_compute_subnetwork.get-gke-credentials-public.region

  enable_autopilot   = true
  initial_node_count = 1

  network    = google_compute_network.network.id
  subnetwork = google_compute_subnetwork.get-gke-credentials-public.id

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.get-gke-credentials-public.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.get-gke-credentials-public.secondary_ip_range[1].range_name
  }

  release_channel {
    channel = "REGULAR"
  }

  timeouts {
    create = "15m"
    update = "15m"
  }

  depends_on = [
    google_project_service.services["container.googleapis.com"],
  ]
}

# Private GKE cluster
resource "google_compute_subnetwork" "get-gke-credentials-private" {
  name          = "get-gke-credentials-private"
  ip_cidr_range = "10.0.128.0/17"
  region        = "us-central1"
  network       = google_compute_network.network.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "get-gke-credentials-private-pods"
    ip_cidr_range = "192.168.128.0/18"
  }

  secondary_ip_range {
    range_name    = "get-gke-credentials-private-services"
    ip_cidr_range = "192.168.192.0/18"
  }
}

resource "google_container_cluster" "get-gke-credentials-private" {
  name     = "get-gke-credentials-private"
  location = google_compute_subnetwork.get-gke-credentials-private.region

  enable_autopilot   = true
  initial_node_count = 1

  network    = google_compute_network.network.id
  subnetwork = google_compute_subnetwork.get-gke-credentials-private.id

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.16/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      display_name = "Access within subnet."
      cidr_block   = google_compute_subnetwork.get-gke-credentials-private.ip_cidr_range
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.get-gke-credentials-private.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.get-gke-credentials-private.secondary_ip_range[1].range_name
  }

  release_channel {
    channel = "REGULAR"
  }

  timeouts {
    create = "15m"
    update = "15m"
  }

  depends_on = [
    google_project_service.services["container.googleapis.com"],
  ]
}

resource "google_gke_hub_membership" "get-get-credentials-private" {
  membership_id = "get-gke-credentials-private"

  endpoint {
    gke_cluster {
      resource_link = google_container_cluster.get-gke-credentials-private.id
    }
  }

  authority {
    issuer = "https://container.googleapis.com/v1/${google_container_cluster.get-gke-credentials-private.id}"
  }
}

resource "google_gke_hub_membership_iam_member" "get-gke-credentials-private" {
  project       = data.google_project.project.project_id
  membership_id = google_gke_hub_membership.get-get-credentials-private.membership_id
  role          = "roles/viewer"
  member        = "serviceAccount:${module.get-gke-credentials.service_account_email}"
}
