# ssh-compute

This configuration sets up two Compute Engine VMs on a VPC. One VM has an external IP while the other does not. Each VM has dedicated SAs attached to them. The goal is for two VMs is to test both IAP based SSH as well as regular SSH using the `ssh-compute` Action.

IAP has been configured to use the VM without external IP. A NAT is also setup to provide egress for this VM. A FW rule allowing ingress for SSH has been created targeting the VM with an external IP. A common SA is granted `compute.instanceAdmin.v1` to allow updating metadata and to SSH into these VMs. This SA has also been granted `roles/iap.tunnelResourceAccessor` for accessing the VM with IAP.