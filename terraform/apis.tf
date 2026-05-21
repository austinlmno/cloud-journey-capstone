# apis.tf
# GCP APIs that need to be enabled before resources can be created.
#
# Doing this in Terraform (rather than gcloud commands) makes the project
# fully reproducible from scratch — a fresh `terraform apply` on a new
# project ID brings everything up.
#
# Phase 1 reference: this is the operational discipline introduced in
# weeks 1-2.

locals {
  required_apis = [
    "compute.googleapis.com",          # VPC, firewall, etc. (weeks 5-6)
    "run.googleapis.com",              # Cloud Run services and jobs (weeks 3-4)
    "cloudscheduler.googleapis.com",   # Scheduled feed polling
    "pubsub.googleapis.com",           # Pub/Sub messaging (weeks 9-10)
    "storage.googleapis.com",          # Cloud Storage (weeks 3-4)
    "bigquery.googleapis.com",         # BigQuery analytics (weeks 7-8)
    "bigquerydatatransfer.googleapis.com",  # Scheduled BQ loads
    "secretmanager.googleapis.com",    # MBTA API key storage
    "iam.googleapis.com",              # Service accounts (weeks 1-2, 11-12)
    "logging.googleapis.com",          # Cloud Logging (weeks 11-12)
    "monitoring.googleapis.com",       # Cloud Monitoring (weeks 11-12)
    "artifactregistry.googleapis.com", # Container images for Cloud Run
    "cloudbilling.googleapis.com",     # Budget alerts
  ]
}

resource "google_project_service" "enabled_apis" {
  for_each = toset(local.required_apis)

  project = var.project_id
  service = each.key

  # Keep APIs enabled even if Terraform tears down resources. Disabling APIs
  # can break unrelated things; safer to leave them on.
  disable_on_destroy         = false
  disable_dependent_services = false
}
