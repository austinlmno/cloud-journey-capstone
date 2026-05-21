# cloud_run.tf
# Cloud Run job (poller) and service (subscriber).
#
# Phase 1 reference: weeks 3-4 (Cloud Run Flask lab, generalized here).
#
# Container image: this Terraform assumes the images already exist in Artifact
# Registry. The first apply will fail until you've built and pushed at least a
# stub image for each. The cycle:
#   1. terraform apply --target=google_artifact_registry_repository.services
#   2. Build and push poller + subscriber images
#   3. terraform apply (full)
#
# A common Phase 2 cleanup: move image builds into a small Cloud Build trigger
# so this two-step dance goes away.

resource "google_artifact_registry_repository" "services" {
  location      = var.region
  repository_id = "${local.name_prefix}-services"
  description   = "Container images for transit telemetry workloads."
  format        = "DOCKER"

  labels = local.common_labels

  depends_on = [google_project_service.enabled_apis]
}

locals {
  # Image URIs are derived from the Artifact Registry repo. The :latest tag is
  # fine for Phase 1; switch to immutable digests once you have CI.
  poller_image     = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.services.repository_id}/poller:latest"
  subscriber_image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.services.repository_id}/subscriber:latest"
}

# Poller — Cloud Run Job, invoked by Cloud Scheduler.
resource "google_cloud_run_v2_job" "poller" {
  name     = "${local.name_prefix}-poller"
  location = var.region

  template {
    template {
      service_account = google_service_account.poller.email
      timeout         = "60s" # Polling should be quick; a long-running poller is a bug.

      containers {
        image = local.poller_image

        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.vehicle_positions.id
        }

        env {
          name  = "MBTA_SECRET_NAME"
          value = "projects/${var.project_id}/secrets/${var.mbta_api_key_secret_id}/versions/latest"
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }

      max_retries = 1
    }
  }

  labels = local.common_labels

  depends_on = [google_project_service.enabled_apis]
}

# Subscriber — Cloud Run Service, processes Pub/Sub messages.
resource "google_cloud_run_v2_service" "subscriber" {
  name     = "${local.name_prefix}-subscriber"
  location = var.region

  template {
    service_account = google_service_account.subscriber.email

    scaling {
      min_instance_count = 0 # Scale to zero — this is the whole point of Cloud Run.
      max_instance_count = 5
    }

    containers {
      image = local.subscriber_image

      env {
        name  = "GCS_BUCKET"
        value = google_storage_bucket.raw_data.name
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  labels = local.common_labels

  depends_on = [google_project_service.enabled_apis]
}
