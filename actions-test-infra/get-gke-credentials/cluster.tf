/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# Enable necessary APIs.
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 9.0"

  project_id = var.gcp_project

  activate_apis = [
    "container.googleapis.com",
  ]
}

# Setup network
module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.5"
  project_id   = module.project-services.project_id
  network_name = "gke-network"

  subnets = [
    {
      subnet_name   = "gke-subnet"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = "us-central1"
    },
  ]

  secondary_ranges = {
    "gke-subnet" = [
      {
        range_name    = "ip-range-pods"
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = "ip-range-svc"
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

# Create a GKE cluster
module "gke" {
  source            = "terraform-google-modules/kubernetes-engine/google"
  version           = "~> 12.0.0"
  project_id        = module.project-services.project_id
  name              = "test-zonal-cluster"
  regional          = false
  region            = "us-central1"
  zones             = ["us-central1-a", "us-central1-b"]
  network           = module.vpc.network_name
  subnetwork        = module.vpc.subnets_names[0]
  ip_range_pods     = module.vpc.subnets_secondary_ranges[0].*.range_name[0]
  ip_range_services = module.vpc.subnets_secondary_ranges[0].*.range_name[1]
}

# Create the service account.
resource "google_service_account" "get-gke-cred-it-sa" {
  project      = module.project-services.project_id
  account_id   = var.get_gke_cred_it_sa_name
  display_name = var.get_gke_cred_it_sa_name
}

# Assign the Container Admin IAM role to the service account.
resource "google_project_iam_member" "get-gke-cred-admin" {
  role   = "roles/container.admin"
  member = "serviceAccount:${google_service_account.get-gke-cred-it-sa.email}"
}

# Create service account key.
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.get-gke-cred-it-sa.name
}
