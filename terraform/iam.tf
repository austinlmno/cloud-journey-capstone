# iam.tf
# Service accounts and role bindings.
#
# Principle: one service account per workload, with the minimum roles each
# workload actually needs. Never use the default Compute Engine service account
# for application identity — it has Editor on the project, which is the textbook
# anti-pattern from the Phase 1 IAM material.
#
# Phase 1 reference: weeks 1-2 (IAM basics), 11-12 (security fundamentals).

# Poller — fetches GTFS-RT feed and publishes to Pub/Sub.
resource "google_service_account" "poller" {
  account_id   = "${local.name_prefix}-poller"
  display_name = "Transit telemetry poller (Cloud Run job)"
  description  = "Fetches GTFS-Realtime feed from MBTA and publishes vehicle position messages to Pub/Sub."
}

resource "google_project_iam_member" "poller_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.poller.email}"

  condition {
    title       = "Only the vehicle-positions topic"
    description = "Limits publish permission to the single topic this workload writes to."
    expression  = "resource.name == \"projects/${var.project_id}/topics/${google_pubsub_topic.vehicle_positions.name}\""
  }
}

resource "google_project_iam_member" "poller_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.poller.email}"

  # Note: scope this further with a condition once the secret resource is
  # in Terraform. For Phase 1 the secret is created out-of-band.
}

# Subscriber — pulls from Pub/Sub and writes to Cloud Storage.
resource "google_service_account" "subscriber" {
  account_id   = "${local.name_prefix}-subscriber"
  display_name = "Transit telemetry subscriber (Cloud Run service)"
  description  = "Consumes vehicle position messages from Pub/Sub and writes them to Cloud Storage."
}

resource "google_project_iam_member" "subscriber_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.subscriber.email}"
}

resource "google_storage_bucket_iam_member" "subscriber_gcs_writer" {
  bucket = google_storage_bucket.raw_data.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.subscriber.email}"
}

# BigQuery loader — service account used by the scheduled load job.
resource "google_service_account" "bq_loader" {
  account_id   = "${local.name_prefix}-bq-loader"
  display_name = "BigQuery loader for transit telemetry"
  description  = "Loads raw GCS data into the partitioned BigQuery table on a schedule."
}

resource "google_project_iam_member" "bq_loader_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.bq_loader.email}"
}

resource "google_storage_bucket_iam_member" "bq_loader_gcs_reader" {
  bucket = google_storage_bucket.raw_data.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.bq_loader.email}"
}
