# Copyright 2024 Google LLC
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

module "deploy-gke" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "deploy-gke"
  repo_description  = "A GitHub Action to deploy workloads to Google Kubernetes Engine."
  repo_homepage_url = "https://cloud.google.com/kubernetes-engine"
  repo_topics = concat([
    "google-kubernetes-engine",
    "gke",
    "kubernetes",
    "deployment",
  ], local.common_topics)

  repo_variables = {
    "IMAGE"          = "nginx:latest"
    "APP_NAME"       = "deploy-gke-app"
    "CLUSTER_REGION" = google_container_cluster.deploy-gke.location
    "CLUSTER_NAME"   = google_container_cluster.deploy-gke.name
    "NAMESPACE"      = "deploy-gke-ns"
    "EXPOSE"         = "80"
  }

  repo_collaborators = {
    teams = {
      "deploy-gke-maintainers" : "push",
    }
    users = {}
  }

  depends_on = [
    google_project_service.services,
  ]
}

resource "google_compute_subnetwork" "deploy-gke" {
  name    = "deploy-gke"
  region  = "us-central1"
  network = google_compute_network.network.id

  ip_cidr_range    = "10.0.2.0/24"
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "deploy-gke-pods"
    ip_cidr_range = "192.168.20.0/24"
  }

  secondary_ip_range {
    range_name    = "deploy-gke-services"
    ip_cidr_range = "192.168.21.0/24"
  }
}

resource "google_compute_instance" "deploy-gke" {
  name         = "deploy-gke"
  machine_type = "e2-micro"
  zone         = google_compute_subnetwork.deploy-gke.region

  # tag for internal firewall policies to allow iap
  tags = ["allow-iap"]

  can_ip_forward            = true
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.deploy-gke.id
  }

  service_account {
    email  = google_service_account.deploy-gke.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    ignore_changes = [
      metadata["deploy-gke"],
    ]
  }
}

resource "google_compute_firewall" "allow_gke_expose" {
  name    = "allow-gke-expose"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.235.240.0/20"]

  target_service_accounts = [google_service_account.deploy-gke.email]
}

resource "google_container_cluster" "deploy-gke" {
  name     = "deploy-gke-cluster"
  location = google_compute_subnetwork.deploy-gke.region
  network  = google_compute_network.network.id

  enable_autopilot         = true
  enable_l4_ilb_subsetting = true
  deletion_protection      = false
  initial_node_count       = 1

  subnetwork = google_compute_subnetwork.deploy-gke.id

  ip_allocation_policy {
    stack_type                    = "IPV4_IPV6"
    cluster_secondary_range_name  = google_compute_subnetwork.deploy-gke.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.deploy-gke.secondary_ip_range[1].range_name
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

# Grant the WIF permissions to manage gke resources.
resource "google_project_iam_member" "deploy-gke-direct-permissions" {
  for_each = toset([
    "roles/container.developer",

    # For verifying deployments in the gke cluster
    "roles/container.clusterViewer",
  ])

  project = data.google_project.project.project_id
  role    = each.value
  member  = "principalSet://iam.googleapis.com/${module.deploy-gke.workload_identity_pool_name}/*"
}
