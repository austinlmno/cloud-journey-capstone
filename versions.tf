# versions.tf
# Provider and backend configuration.
#
# Pin provider versions explicitly — uncontrolled provider upgrades are one of
# the most common ways a working Terraform repo silently breaks between sessions.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # State backend.
  # Phase 1: comment out and use local state to keep things simple.
  # Phase 2 onward: switch to GCS backend so state is shared and versioned.
  #
  # backend "gcs" {
  #   bucket = "REPLACE-ME-tfstate-bucket"
  #   prefix = "transit-telemetry/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
