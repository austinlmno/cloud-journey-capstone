# storage.tf
# Raw data bucket — Cloud Storage as the bronze layer of the data lake.
#
# Phase 1 reference: weeks 3-4 (Cloud Storage with lifecycle rules).
#
# Lifecycle design:
# - Standard tier for the first 30 days (active analysis window)
# - Nearline at 30 days (occasional reload into BigQuery)
# - Coldline at 90 days (rarely accessed but kept)
# - Delete at 365 days (cost cap for a study project)
#
# Versioning is on so accidental deletes during development are recoverable.

resource "google_storage_bucket" "raw_data" {
  name     = "${var.project_id}-${local.name_prefix}-raw"
  location = var.region

  # Uniform access — no per-object ACLs. The IAM-only model is what every
  # real production bucket should use; per-object ACLs are a legacy footgun.
  uniform_bucket_level_access = true

  # Public access prevention — defense-in-depth, even though IAM bindings are
  # the actual access control. Prevents the bucket from ever becoming public
  # by accident.
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  # Clean up old non-current versions aggressively — versioning is for safety,
  # not long-term history.
  lifecycle_rule {
    condition {
      age                = 7
      with_state         = "ARCHIVED"
      num_newer_versions = 1
    }
    action {
      type = "Delete"
    }
  }

  labels = local.common_labels

  depends_on = [google_project_service.enabled_apis]
}
