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

module "deploy-cloud-functions" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "deploy-cloud-functions"
  repo_description  = "A GitHub Action that deploys source code to Google Cloud Functions."
  repo_homepage_url = "https://cloud.google.com/"
  repo_topics = concat([
    "cloud-functions",
    "gcf",
    "google-cloud-functions",
  ], local.common_topics)

  repo_secrets = {
    "PUBSUB_TOPIC_NAME" : google_pubsub_topic.topic.id
    "SECRET_NAME" : google_secret_manager_secret.secret.id
    "SECRET_VERSION_NAME" : google_secret_manager_secret_version.version.id
  }

  repo_collaborators = {
    users = {
      "google-github-actions-bot" : "triage"
    }

    teams = {
      "maintainers" : "admin"
    }
  }

  depends_on = [
    google_project_service.services,
  ]
}

# Grant the custom runtime service account permissions.
resource "google_secret_manager_secret_iam_member" "deploy-cloud-functions-secret-accessor" {
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.deploy-cloud-functions.service_account_email}"
}

# Grant the custom service account permissions to deploy.
resource "google_project_iam_member" "deploy-cloud-functions-developer" {
  project = data.google_project.project.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${module.deploy-cloud-functions.service_account_email}"
}

# Grant the custom service account permissions to impersonate the Cloud
# Functions runtime service account.
resource "google_service_account_iam_member" "deploy-cloud-functions-runtime-account" {
  service_account_id = data.google_app_engine_default_service_account.account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.deploy-cloud-functions.service_account_email}"
}

# Grant the custom service account permissions to impersonate itself.
resource "google_service_account_iam_member" "deploy-cloud-functions-self" {
  service_account_id = module.deploy-cloud-functions.service_account_name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.deploy-cloud-functions.service_account_email}"
}
