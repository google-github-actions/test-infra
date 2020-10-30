/*
 * Copyright 2020 Google LLC
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

locals {
  gh_org               = "google-github-actions"
  template_action_root = "actions-repo-template"
  template_repo_files  = fileset(local.template_action_root, "**")
}

provider "github" {
  version      = "~> 3.1.0"
  organization = local.gh_org
}

resource "github_repository" "example" {
  name               = "google-github-actions-template"
  description        = "An actions template for bootstrapping Google Github actions"
  allow_merge_commit = false
  allow_rebase_merge = false
  has_issues         = true
  is_template        = true
  auto_init          = true
}

resource "github_repository_file" "template_files" {
  for_each = toset(local.template_repo_files)

  repository          = github_repository.example.name
  file                = each.value
  content             = file("${local.template_action_root}/${each.value}")
  branch              = "main"
  overwrite_on_create = true
}

output "github-actions-template-repo-name" {
  value       = github_repository.example.name
  description = "Repo name for Google Github Actions template repo"
}