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

  depends_on = [
    google_project_service.services,
  ]
}
