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

locals {
  app_name  = "deploy-gke-app"
  namespace = "deploy-gke-ns"
  expose    = "80"
  image     = "nginx:latest"
}

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
    "IMAGE"          = local.image
    "APP_NAME"       = local.app_name
    "CLUSTER_REGION" = google_container_cluster.deploy_gke.location
    "CLUSTER_NAME"   = google_container_cluster.deploy_gke.name
    "NAMESPACE"      = local.namespace
    "EXPOSE"         = local.expose
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

resource "google_container_cluster" "deploy_gke" {
  name     = "deploy-gke-cluster"
  location = "us-central1"
  network  = google_compute_network.network.id

  initial_node_count = 1

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

# Grant the custom service account permissions to manage gke resources.
resource "google_project_iam_member" "deploy-gke-roles" {
  for_each = toset([
    "roles/container.developer",

    # For verifying deployments in the gke cluster
    "roles/container.clusterViewer",
  ])

  project = data.google_project.project.project_id
  role    = each.value
  member  = "serviceAccount:${module.deploy-gke.service_account_email}"
}
