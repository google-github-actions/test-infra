# Copyright 2025 Google LLC
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

module "render-parameter-version" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "render-parameter-version"
  repo_description  = "A GitHub Action to render a parameter version in Parameter Manager."
  repo_homepage_url = "https://cloud.google.com/secret-manager/parameter-manager/docs/overview"
  repo_topics = concat([
    "secret-manager",
    "parameter-manager",
    "config",
  ], local.common_topics)

  repo_variables = {}

  repo_visibility = "private"

  repo_collaborators = {
    teams = {
      "render-parameter-version-maintainers" : "push",
    }
    users = {}
  }

  depends_on = [
    google_project_service.services,
  ]
}
