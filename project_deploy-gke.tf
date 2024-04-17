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
  repo_description  = "A GitHub Action to SSH into a Google Compute Engine instance."
  repo_homepage_url = "https://cloud.google.com/kubernetes-engine"
  repo_topics = concat([
    "google-kubernetes-engine",
    "gke",
    "kubernetes",
    "deployment",
  ], local.common_topics)

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
# Grant the custom service account permissions to manage gke resources.
resource "google_project_iam_member" "deploy-gke-roles" {
  for_each = toset([
    "roles/container.developer",
  ])

  project = data.google_project.project.project_id
  role    = each.value
  member  = "serviceAccount:${module.deploy-gke.service_account_email}"
}
