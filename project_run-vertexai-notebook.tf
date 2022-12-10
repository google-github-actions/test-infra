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

module "run-vertexai-notebook" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "run-vertexai-notebook"
  repo_description  = "A GitHub Action for running a Google Cloud Vertex AI notebook."
  repo_homepage_url = "https://cloud.google.com/vertex-ai"
  repo_topics = concat([
    "artificial-intelligence",
    "machine-learning",
    "ml-notebooks",
    "vertex-ai",
  ], local.common_topics)

  depends_on = [
    google_project_service.services,
  ]
}
