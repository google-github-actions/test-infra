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

variable "github_organization_name" {
  type        = string
  description = "Human organization name."
}

variable "github_organization_id" {
  type        = number
  description = "Numeric organization ID."
}

variable "repo_name" {
  type        = string
  description = "Name of the GitHub repository, not including the owner (e.g. foo)."
}

variable "repo_description" {
  type        = string
  description = "Description of the GitHub repository."
}

variable "repo_homepage_url" {
  type        = string
  description = "URL for the homepage for the GitHub repository."
}

variable "repo_topics" {
  type        = list(string)
  description = "List of repository topics."
  default     = []
}

variable "repo_visibility" {
  type        = string
  description = "Visibility of the respository."
  default     = "public"
}

variable "repo_collaborators" {
  type = object({
    users = map(string)
    teams = map(string)
  })
  description = "List of repository collaborators."
  default = {
    users = {}
    teams = {}
  }
}

variable "repo_secrets" {
  type        = map(string)
  description = "List of additional GitHub repository secrets."
  default     = {}
}

variable "repo_variables" {
  type        = map(string)
  description = "List of additional GitHub repository variables. Note these will be available as plaintext!"
  default     = {}
}
