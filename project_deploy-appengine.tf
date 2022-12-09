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

module "deploy-appengine" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "deploy-appengine"
  repo_description  = "A GitHub Action that deploys source code to Google App Engine."
  repo_homepage_url = "https://cloud.google.com/appengine"
  repo_topics = concat([
    "app-engine",
    "appengine",
    "gae",
    "google-app-engine",
    "google-appengine",
  ], local.common_topics)

  depends_on = [
    google_project_service.services,
  ]
}

# Create the AppEngine app.
resource "google_app_engine_application" "application" {
  location_id = "us-central"
  depends_on = [
    google_project_service.services["appengine.googleapis.com"],
  ]
}

# Assign roles.
resource "google_project_iam_member" "permissions" {
  for_each = toset([
    "roles/appengine.appAdmin",
    "roles/storage.admin",
    "roles/cloudbuild.builds.editor",
  ])

  project = data.google_project.project.project_id
  role    = each.key
  member  = "serviceAccount:${module.deploy-appengine.service_account_email}"
}

# Allow deploy appengine SA to use app engine default service account.
resource "google_service_account_iam_member" "appengine-default-sa-user" {
  service_account_id = data.google_app_engine_default_service_account.account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.deploy-appengine.service_account_email}"
}
