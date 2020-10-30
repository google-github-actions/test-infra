terraform {
  backend "gcs" {
    bucket = "actions-seed-tfstate-b4fa"
    prefix = "state/seed"
  }
}