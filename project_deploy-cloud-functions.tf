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
  repo_homepage_url = "https://cloud.google.com/functions"
  repo_topics = concat([
    "cloud-functions",
    "gcf",
    "google-cloud-functions",
  ], local.common_topics)

  repo_variables = {
    "PUBSUB_TOPIC_NAME" : google_pubsub_topic.deploy-cloud-functions.id
    "SECRET_NAME" : google_secret_manager_secret.secret.id
    "SECRET_VERSION_NAME" : google_secret_manager_secret_version.version.id
  }

  depends_on = [
    google_project_service.services,
  ]
}

# Grant the runtime service account permissions to access secrets.
resource "google_secret_manager_secret_iam_member" "deploy-cloud-functions-secret-accessor" {
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.deploy-cloud-functions.service_account_email}"
}

# Grant the runtime service account permissions to receive eventarc events.
resource "google_project_iam_member" "deploy-cloud-functions-eventarc-receiver" {
  project = data.google_project.project.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${module.deploy-cloud-functions.service_account_email}"
}

# Enable the Workload Identity to impersonate the runtime service account (required for deployment).
resource "google_service_account_iam_member" "deploy-cloud-functions-wif-impersonate-runtime" {
  service_account_id = module.deploy-cloud-functions.service_account_name
  role               = "roles/iam.serviceAccountUser"
  member             = "principalSet://iam.googleapis.com/${module.deploy-cloud-functions.workload_identity_pool_name}/*"
}

# Enable the Workload Identity to deploy Cloud Functions.
resource "google_project_iam_member" "deploy-cloud-functions-wif-cloud-functions-deployer" {
  project = data.google_project.project.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "principalSet://iam.googleapis.com/${module.deploy-cloud-functions.workload_identity_pool_name}/*"
}

resource "google_pubsub_topic" "deploy-cloud-functions" {
  name = module.deploy-cloud-functions.iam_safe_repo_name

  depends_on = [
    google_project_service.services["pubsub.googleapis.com"],
  ]
}
