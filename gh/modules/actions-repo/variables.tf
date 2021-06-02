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

variable "gh_org" {
  type        = string
  description = "The GitHub org name"
}

variable "repo_name" {
  type        = string
  description = "The repository name"
}

variable "description" {
  type        = string
  description = "The repository description."
}

variable "secrets" {
  type        = map(string)
  description = "Github Actions secrets for this reporsitory."
  default     = {}
}

variable "template_repo_name" {
  type        = string
  description = "The template repository name"
  default     = ""
}

variable "create_labels" {
  type        = bool
  description = "Auto creates labels"
  default     = true
}

variable "allow_google_bot" {
  type        = bool
  description = "Allows bot to auto build and create releases"
  default     = true
}

variable "gha_bot_token" {
  type        = string
  description = "Bot PAT for triage"
  default     = ""
}

variable "status_checks" {
  type        = list(string)
  description = "List of status checks required."
}

variable "vulnerability_alerts" {
  type        = bool
  default     = true
  description = "Flag to enable Dependabot alerts"
}

variable "require_code_owner_reviews" {
  type        = bool
  default     = true
  description = "Flag to enable code owner reviews before merge"
}
