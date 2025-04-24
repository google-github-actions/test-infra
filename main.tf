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

locals {
  common_topics = [
    "actions",
    "gcp",
    "github-actions",
    "google-cloud-platform",
    "google-cloud",
  ]
}

provider "google" {
  project = var.project_id
}

# This defines the list of services needed by the repo module. The repo module
# does not declare its own services because that would be O(N) service
# enablement and exhaust API quota.
resource "google_project_service" "services" {
  for_each = toset([
    "appengine.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "connectgateway.googleapis.com",
    "container.googleapis.com",
    "containersecurity.googleapis.com",
    "eventarc.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "iap.googleapis.com",
    "parametermanager.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage-api.googleapis.com",
    "storage.googleapis.com",
    "vpcaccess.googleapis.com",
    "workflows.googleapis.com",
  ])

  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [
    google_project_service.services["cloudresourcemanager.googleapis.com"],
  ]
}

resource "google_app_engine_application" "application" {
  location_id = "us-central"
  depends_on = [
    google_project_service.services["appengine.googleapis.com"],
  ]
}

data "google_secret_manager_secret_version" "bot" {
  secret = "github-actions-bot-pat"

  depends_on = [
    google_project_service.services["secretmanager.googleapis.com"],
  ]
}

data "google_app_engine_default_service_account" "account" {
  depends_on = [
    google_app_engine_application.application,
  ]
}

data "google_project" "project" {
  project_id = google_app_engine_application.application.project
}

data "google_compute_default_service_account" "account" {}

resource "google_secret_manager_secret" "secret" {
  secret_id = "test-secret"

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.services["secretmanager.googleapis.com"],
  ]
}

resource "google_secret_manager_secret_version" "version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = "my super secret data"
}

resource "google_secret_manager_regional_secret" "regional-secret" {
  secret_id = "test-regional-secret"
  location  = "us-central1"

  depends_on = [
    google_project_service.services["secretmanager.googleapis.com"],
  ]
}

resource "google_secret_manager_regional_secret_version" "regional-version" {
  secret      = google_secret_manager_regional_secret.regional-secret.id
  secret_data = "my regionally secret data"
}

# Create a dedicated network with egress NAT.
resource "google_compute_network" "network" {
  name        = "github-actions-network"
  description = "Network for GitHub Actions infrastructure."

  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
  routing_mode             = "GLOBAL"

  depends_on = [
    google_project_service.services["compute.googleapis.com"],
  ]
}

resource "google_compute_router" "router" {
  name    = "github-actions-router"
  region  = "us-central1"
  network = google_compute_network.network.id
}

resource "google_compute_router_nat" "nat" {
  name   = "github-actions-nat"
  region = google_compute_router.router.region
  router = google_compute_router.router.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Create a parameter for render-parameter-version and a secret for render_secret in the parameter.
resource "google_parameter_manager_parameter" "parameter" {
  parameter_id = "tf-parameter"
  format       = "YAML"
}

resource "google_secret_manager_secret" "secret-for-parameter" {
  secret_id = "tf-secret-for-parameter"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret-version-for-parameter" {
  secret      = google_secret_manager_secret.secret-for-parameter.id
  secret_data = "parameter-version-data"
}

resource "google_parameter_manager_parameter_version" "parameter-version" {
  parameter            = google_parameter_manager_parameter.parameter.id
  parameter_version_id = "tf-parameter-version"
  parameter_data = yamlencode({
    "tempsecret" : "__REF__(//secretmanager.googleapis.com/${google_secret_manager_secret_version.secret-version-for-parameter.name})"
  })
}

# Create a regional parameter for render-parameter-version and a regional secret for render_secret in the parameter.
resource "google_parameter_manager_regional_parameter" "regional-parameter" {
  parameter_id = "tf-regional-parameter"
  location     = "us-central1"
  format       = "YAML"
}

resource "google_secret_manager_regional_secret" "regional-secret-for-parameter" {
  secret_id = "tf-regional-secret-for-parameter"
  location  = "us-central1"
}

resource "google_secret_manager_regional_secret_version" "regional-secret-version-for-parameter" {
  secret      = google_secret_manager_regional_secret.regional-secret-for-parameter.id
  secret_data = "regional-parameter-version-data"
}

resource "google_parameter_manager_regional_parameter_version" "regional-parameter-version" {
  parameter            = google_parameter_manager_regional_parameter.regional-parameter.id
  parameter_version_id = "tf-regional-parameter-version"
  parameter_data = yamlencode({
    "tempsecret" : "__REF__(//secretmanager.googleapis.com/${google_secret_manager_regional_secret_version.regional-secret-version-for-parameter.name})"
  })
}
