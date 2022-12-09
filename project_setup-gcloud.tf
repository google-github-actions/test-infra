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

module "setup-gcloud" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "setup-gcloud"
  repo_description  = "A GitHub Action for installing and configuring the gcloud CLI."
  repo_homepage_url = "https://cloud.google.com/sdk/docs"
  repo_topics = concat([
    "bq",
    "gcloud-cli",
    "gcloud-sdk",
    "gcloud",
    "gsutil",
  ], local.common_topics)

  repo_secrets = {
    "SERVICE_ACCOUNT_KEY_JSON" : google_service_account_key.setup-gcloud-key.private_key
  }

  depends_on = [
    google_project_service.services,
  ]
}

# The setup-gcloud action needs an exported service account key to test the
# SAKE integration.
resource "google_service_account_key" "setup-gcloud-key" {
  service_account_id = module.auth.service_account_name
}
