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

module "create-cloud-deploy-release" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "create-cloud-deploy-release"
  repo_description  = "A GitHub Action for creating releases via Cloud Deploy."
  repo_homepage_url = "https://cloud.google.com/deploy"
  repo_topics = concat([
    "ci-cd",
    "cloud-deploy",
    "google-cloud-deploy",
  ], local.common_topics)

  repo_collaborators = {
    teams = {}
    users = {
      "henrybell" : "maintain",
    }
  }

  depends_on = [
    google_project_service.services,
  ]
}

# Grant the custom service account permissions to create cloud deploy jobs.
resource "google_project_iam_member" "create-cloud-deploy-release-roles" {
  for_each = toset([
    "roles/clouddeploy.operator",
    "roles/clouddeploy.releaser",
    "roles/storage.admin",
  ])

  project = data.google_project.project.project_id
  role    = each.value
  member  = "serviceAccount:${module.create-cloud-deploy-release.service_account_email}"
}

# Grant the custom service account permissions to impersonate the default runtime
# service account.
resource "google_service_account_iam_member" "create-cloud-deploy-release-default-sa-user" {
  service_account_id = data.google_compute_default_service_account.account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.create-cloud-deploy-release.service_account_email}"
}
