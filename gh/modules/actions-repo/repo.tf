/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "github_repository" "repo" {
  name                   = var.repo_name
  description            = var.description
  allow_merge_commit     = false
  allow_rebase_merge     = false
  is_template            = false
  has_issues             = true
  delete_branch_on_merge = var.delete_branch_on_merge
  topics                 = var.topics
  has_downloads          = var.has_downloads
  vulnerability_alerts   = var.vulnerability_alerts
  dynamic "template" {
    for_each = var.template_repo_name == "" ? [] : [var.template_repo_name]
    content {
      owner      = local.gh_org
      repository = template.value
    }
  }
}

resource "github_branch_protection" "branch_protection" {
  repository_id  = github_repository.repo.node_id
  pattern        = "main"
  enforce_admins = var.enforce_admins
  required_status_checks {
    strict   = true
    contexts = var.status_checks
  }
  required_pull_request_reviews {
    dismiss_stale_reviews      = false
    require_code_owner_reviews = var.require_code_owner_reviews
  }
}

resource "github_repository_collaborator" "google_bot" {
  count                       = var.allow_google_bot ? 1 : 0
  repository                  = github_repository.repo.name
  username                    = "google-github-actions-bot"
  permission                  = "triage"
  permission_diff_suppression = true
}
