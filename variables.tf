# variables.tf
# All inputs to the Terraform configuration.
#
# Convention: every variable has a description and a type. No defaults for
# environment-specific values (project_id) — those should be required so a
# misconfigured environment fails loudly rather than silently using the wrong one.

variable "project_id" {
  description = "GCP project ID. Use a dedicated project for this work — do not share with personal projects."
  type        = string
}

variable "region" {
  description = "Primary region for regional resources. us-east1 is closest to MBTA's data center; us-central1 is the GCP default."
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "Primary zone within the region. Only used where a zonal resource is unavoidable."
  type        = string
  default     = "us-east1-b"
}

variable "environment" {
  description = "Environment name. Used as a label on all resources and as a name prefix where uniqueness matters."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "mbta_api_key_secret_id" {
  description = "Name of the Secret Manager secret holding the MBTA API key. The secret is created out-of-band so the key never lives in Terraform state."
  type        = string
  default     = "mbta-api-key"
}

variable "budget_alert_thresholds_usd" {
  description = "Budget alert thresholds in USD. Set early — this is the single most important config for any new GCP project."
  type        = list(number)
  default     = [50, 100, 250]
}

# Computed values used across modules. Centralizing here keeps naming consistent
# and makes the project-prefix easy to change if needed later.
locals {
  name_prefix = "transit-${var.environment}"

  common_labels = {
    project     = "transit-telemetry"
    environment = var.environment
    managed_by  = "terraform"
  }
}
