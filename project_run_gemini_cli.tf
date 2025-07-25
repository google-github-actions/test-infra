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

module "run-gemini-cli" {
  source = "./modules/project"

  // TODO: make public before release
  repo_visibility = "internal"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "run-gemini-cli"
  repo_description  = "A GitHub Action invoking the Gemini CLI."
  repo_homepage_url = "https://github.com/google-gemini/gemini-cli"
  repo_topics = concat([
    "gemini",
    "gemini-cli",
    "ai",
  ], local.common_topics)

  repo_collaborators = {
    teams = {
      "run-gemini-cli-maintainers" : "push",
    }
    users = {}
  }


  depends_on = [
    google_project_service.services,
  ]
}
