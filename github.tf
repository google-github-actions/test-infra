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

provider "github" {
  owner = var.github_organization_name
}

data "github_organization" "organization" {
  name = var.github_organization_name
}

resource "github_actions_organization_secret" "secrets" {
  for_each = {
    "ACTIONS_BOT_TOKEN" : data.google_secret_manager_secret_version.bot.secret_data
  }

  secret_name     = each.key
  plaintext_value = each.value
  visibility      = "all"
}
