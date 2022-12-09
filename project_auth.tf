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

module "auth" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "auth"
  repo_description  = "A GitHub Action for authenticating to Google Cloud."
  repo_homepage_url = "https://cloud.google.com/"
  repo_topics = concat([
    "authentication",
    "iam",
    "identity",
    "security",
  ], local.common_topics)

  repo_secrets = {
    "SERVICE_ACCOUNT_KEY_JSON" : google_service_account_key.auth-key.private_key
    "SECRET_NAME" : google_secret_manager_secret.secret.secret_id
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

# The auth action needs an exported service account key to test the
# "credentials_json" input.
resource "google_service_account_key" "auth-key" {
  service_account_id = module.auth.service_account_name
}

resource "google_secret_manager_secret_iam_member" "auth-secret-accessor" {
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.auth.service_account_email}"
}
