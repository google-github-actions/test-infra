/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  gh_org = "google-github-actions"

  labels = [
    {
      name : "enhancement",
      color : "a2eeef",
      description : "New feature or request"
    },
    {
      name : "bug",
      color : "d73a4a"
      description : "Something isn't working"
    },
    {
      name : "duplicate",
      color : "cfd3d7"
      description : "This issue or pull request already exists"
    },
    {
      name : "good first issue",
      color : "7057ff"
      description : "Good for newcomers"
    },
    {
      name : "help wanted",
      color : "008672",
      description : "Extra attention is needed"
    },
    {
      name : "invalid",
      color : "e4e669",
      description : "Something doesn't seem right"
    },
    {
      name : "question",
      color : "d876e3",
      description : "Further information is requested"
    },
    {
      name : "wontfix",
      color : "db643d",
      description : "This will not be worked on"
    },
    {
      name : "triaged",
      color : "322560",
      description : "Scoped and ready for work"
    },
    {
      name : "upstream",
      color : "B580D1",
      description : "Work required on upstream dependencies (gcloud binary, API etc)"
    },
    {
      name : "security",
      color : "801336",
      description : "Fixes a security vulnerability or lapse in best practice"
    },
    {
      name : "refactor",
      color : "004445",
      description : "Updates for readability, code cleanliness, DRYness, etc."
    },
    {
      name : "blocked",
      color : "ef4339",
      description : "Blocked by some other work"
    },
    {
      name : "P1",
      color : "b01111",
      description : "highest priority issues"
    },
    {
      name : "P2",
      color : "b4451f",
      description : "high priority issues"
    },
    {
      name : "P3",
      color : "e7d87d",
      description : "medium priority issues"
    },
    {
      name : "P4",
      color : "62a1db",
      description : "low priority issues"
    },
    {
      name : "release-please:force-run",
      color : "e7d87d",
      description : "Force release-please to check for changes."
    },
    {
      name : "waiting-response",
      color : "5319e7",
      description : "Waiting for issue author to respond."
    },
    {
      name : "cla: yes",
      color : "98fb00",
      description : "User has signed the Contributor License Agreement"
    },
    {
      name : "cla: no",
      color : "ff0040",
      description : "User has not signed the Contributor License Agreement"
    },
    {
      name : "automerge",
      color : "C2E0C6",
      description : "Merge the pull request once unit tests and other checks pass."
    },
    {
      name : "autorelease: pending",
      color : "e8e8e8",
      description : ""
    },
    {
      name : "autorelease: tagged",
      color : "e8e8e8",
      description : ""
    }
  ]
  repos = data.terraform_remote_state.repos.outputs.repos
  repo_labels = {
    for o in flatten([
      for repo in local.repos :
      [
        for label in local.labels :
        {
          # repo is of form org/repo_name, we require just repo_name
          "repo" : split("/", repo)[1],
          "name" : label.name,
          "color" : label.color,
          "description" : label.description
        }
      ]
    ]) :
    "${o.repo}/${o.name}" => o
  }
}

resource "github_issue_label" "test_repo" {
  for_each    = local.repo_labels
  repository  = each.value.repo
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
}
