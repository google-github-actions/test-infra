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

module "deploy-cloudrun" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "deploy-cloudrun"
  repo_description  = "A GitHub Action for deploying services to Google Cloud Run."
  repo_homepage_url = "https://cloud.google.com/run"
  repo_topics = concat([
    "cloud-run",
    "cloudrun",
    "google-cloud-run",
  ], local.common_topics)

  repo_variables = {
    "SECRET_NAME" : google_secret_manager_secret.secret.secret_id
  }

  depends_on = [
    google_project_service.services,
  ]
}

# Grant the default runtime service account permissions to access the secret.
resource "google_secret_manager_secret_iam_member" "deploy-cloudrun-secret-accessor" {
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_compute_default_service_account.account.email}"
}

# Grant the custom service account permissions to deploy.
resource "google_project_iam_member" "deploy-cloudrun-admin" {
  for_each = toset([
    # Permission to deploy and update services.
    "roles/run.admin",

    # Permissions required for source uploads: https://cloud.google.com/run/docs/deploying-source-code.
    "roles/artifactregistry.admin",
    "roles/cloudbuild.builds.editor",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/storage.admin",
  ])

  project = data.google_project.project.project_id
  role    = each.value
  member  = "serviceAccount:${module.deploy-cloudrun.service_account_email}"
}

# Grant the custom service account permissions to impersonate the runtime
# default runtime service account.
resource "google_service_account_iam_member" "deploy-cloudrun-impersonate-compute" {
  service_account_id = data.google_compute_default_service_account.account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.deploy-cloudrun.service_account_email}"
}
