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
  version = "~> 13.0"

  project_id = var.gcp_project

  activate_apis = [
    "container.googleapis.com",
    "connectgateway.googleapis.com",
    "anthos.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]
}

# Setup network
module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 5.0"
  project_id   = module.project-services.project_id
  network_name = "gke-network"

  subnets = [
    {
      subnet_name   = "gke-subnet"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = "us-central1"
    },
    {
      subnet_name           = "priv-gke-subnet"
      subnet_ip             = "10.0.128.0/17"
      subnet_region         = "us-central1"
      subnet_private_access = true
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
    ],
    "priv-gke-subnet" = [
      {
        range_name    = "ip-range-pods"
        ip_cidr_range = "192.168.128.0/18"
      },
      {
        range_name    = "ip-range-svc"
        ip_cidr_range = "192.168.192.0/18"
      },
    ]
  }
}

# outbound access for private cluster nodes 
module "cloud-nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "~> 2.2"
  project_id    = module.project-services.project_id
  region        = "us-central1"
  router        = "router"
  network       = module.vpc.network_self_link
  create_router = true
}

# Create a GKE cluster
module "gke" {
  source            = "terraform-google-modules/kubernetes-engine/google"
  version           = "~> 21.0"
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

# Assign roles to the test service account.
# container.admin for cluster + k8s api
# gkehub.viewer for testing membership discovery
# gkehub.gatewayAdmin for using connect gateway
resource "google_project_iam_member" "get-gke-cred-roles" {
  for_each = toset(["roles/container.admin", "roles/gkehub.viewer", "roles/gkehub.gatewayAdmin"])
  project  = module.project-services.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.get-gke-cred-it-sa.email}"
}

# Create service account key.
resource "google_service_account_key" "key" {
  service_account_id = google_service_account.get-gke-cred-it-sa.name
}

# Private GKE cluster for testing Connect Gateway
module "priv-gke" {
  source                        = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                       = "~> 21.0"
  project_id                    = module.project-services.project_id
  name                          = "test-priv-cluster"
  regional                      = false
  region                        = "us-central1"
  zones                         = ["us-central1-a", "us-central1-b"]
  network                       = module.vpc.network_name
  subnetwork                    = module.vpc.subnets_names[1]
  ip_range_pods                 = module.vpc.subnets_secondary_ranges[1].*.range_name[0]
  ip_range_services             = module.vpc.subnets_secondary_ranges[1].*.range_name[1]
  enable_private_endpoint       = true
  deploy_using_private_endpoint = true
  enable_private_nodes          = true
  master_ipv4_cidr_block        = "172.16.0.16/28"
  master_authorized_networks = [{
    cidr_block   = "10.0.128.0/17"
    display_name = "Access within subnet"
  }]
}
