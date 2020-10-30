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
  gh_org = "google-github-actions"
  repos = [
    {
      name : "test-infra",
      description : "Test infrastructure for Google Github Actions.",
      templated : false
    },
  ]
}

module "repos" {
  source = "../modules/actions-repo"
  for_each = { for repo in local.repos : repo.name => {
    description : repo.description,
    # by default use templated repos,if not set to false
    templated : can(repo.templated) ? repo.templated : true
    # create secrets if set
    secrets : can(repo.secrets) ? repo.secrets : {}
  } }
  gh_org      = local.gh_org
  repo_name   = each.key
  description = each.value.description
  secrets     = each.value.secrets
  # if templated repo use google-github-actions-template
  template_repo_name = each.value.templated ? "google-github-actions-template" : ""
}