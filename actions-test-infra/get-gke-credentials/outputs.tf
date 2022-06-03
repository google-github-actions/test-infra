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

locals {
  secrets = {
    "WIF_PROVIDER_NAME" : module.oidc.provider_name,
    "GET_GKE_CRED_SA_EMAIL" : google_service_account.get-gke-cred-it-sa.email,
    "GET_GKE_CRED_SA_KEY_JSON" : base64decode(google_service_account_key.key.private_key),
    "GET_GKE_CRED_SA_KEY_B64" : google_service_account_key.key.private_key,
    "GET_GKE_CRED_CLUSTER_NAME" : module.gke.name,
    "GET_GKE_CRED_CLUSTER_LOCATION" : module.gke.location,
    "GET_GKE_PRIV_CLUSTER_NAME" : module.priv-gke.name,
    "GET_GKE_PRIV_CLUSTER_LOCATION" : module.priv-gke.location,
    "GET_GKE_CRED_PROJECT" : var.gcp_project
  }
}

# <k,v> pair of secrets for repo
output "secrets" {
  value      = local.secrets
  sensitive  = true
  depends_on = [module.gke.endpoint]
}

# Manual bootstrap as hub registration via TF does not install agent 
output "bootstrap_priv_cluster_cgw" {
  description = "gcloud commands to bootstrap the Private cluster for testing Connect Gateway"
  value       = <<-EOF
  gcloud container clusters get-credentials ${module.priv-gke.name} --internal-ip --region ${module.priv-gke.location} --project=${var.gcp_project}
  gcloud container fleet memberships register ${module.priv-gke.name}-membership --gke-uri=https://container.googleapis.com/v1/${module.priv-gke.cluster_id} --enable-workload-identity --internal-ip --project ${var.gcp_project}
  gcloud alpha container hub memberships generate-gateway-rbac  --membership=${module.priv-gke.name}-membership --role=clusterrole/cluster-admin --users=${google_service_account.get-gke-cred-it-sa.email} --kubeconfig=$HOME/.kube/config --context gke_${var.gcp_project}_${module.priv-gke.location}_${module.priv-gke.name} --project=${var.gcp_project} --apply
  EOF
}
