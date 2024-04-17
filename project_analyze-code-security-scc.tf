# Copyright 2024 Google LLC
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

module "analyze-code-security-scc" {
  source = "./modules/project"

  github_organization_name = data.github_organization.organization.orgname
  github_organization_id   = data.github_organization.organization.id

  repo_name         = "analyze-code-security-scc"
  repo_description  = "A GitHub Action to analyze Terraform and IaC configurations in Security Command Center."
  repo_homepage_url = "https://cloud.google.com/security-command-center"
  repo_topics = concat([
    "cloud-security",
    "cloud-security-command-center",
    "security-command-center",
    "scc",
    "security",
  ], local.common_topics)

  repo_collaborators = {
    teams = {
      "analyze-code-security-scc-maintainers" : "push",
    }
    users = {}
  }

  depends_on = [
    google_project_service.services,
  ]
}
# Grant the custom service account permissions to manage scc resources.
resource "google_project_iam_member" "analyze-code-security-scc-roles" {
  for_each = toset([
    "roles/securitycenter.admin",
  ])

  project = data.google_project.project.project_id
  role    = each.value
  member  = "serviceAccount:${module.analyze-code-security-scc.service_account_email}"
}
