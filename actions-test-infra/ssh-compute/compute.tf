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

# VPC and subnet
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 3.0"

  project_id   = module.project-services.project_id
  network_name = "test-ssh-compute-net"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "test-ssh-compute-subnet"
      subnet_ip             = "10.127.0.0/20"
      subnet_region         = "us-central1"
      subnet_private_access = true
    }
  ]
}

# NAT for egress from VM without external IP
module "cloud-nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "~> 2.1.0"

  project_id    = module.project-services.project_id
  region        = "us-central1"
  router        = "ssh-compute-router"
  network       = module.vpc.network_self_link
  create_router = true
}

# VM with IAP setup
module "ssh-iap-vm" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "~> 4.0"

  network       = module.vpc.network_self_link
  subnet        = module.vpc.subnets_self_links[0]
  project       = module.project-services.project_id
  host_project  = module.project-services.project_id
  name          = "ssh-iap-vm"
  zone          = "us-central1-a"
  image_project = "debian-cloud"
  image_family  = "debian-10"
  machine_type  = "f1-micro"
  members       = ["serviceAccount:${google_service_account.ssh-sa.email}"]
}
