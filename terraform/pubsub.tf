# pubsub.tf
# Pub/Sub messaging layer between poller and subscriber.
#
# Phase 1 reference: weeks 9-10 (Pub/Sub).
#
# Design notes worth ADR-ing later:
# - One topic for vehicle positions. Trip updates and service alerts can get
#   their own topics if/when they're added.
# - Message retention default is 7 days; bumped to 7 days here for replay
#   capability during development.
# - Dead-letter topic added for messages that fail processing repeatedly — this
#   is the pattern you want from day one even though it feels like overhead.

resource "google_pubsub_topic" "vehicle_positions" {
  name                       = "${local.name_prefix}-vehicle-positions"
  message_retention_duration = "604800s" # 7 days
  labels                     = local.common_labels

  depends_on = [google_project_service.enabled_apis]
}

resource "google_pubsub_topic" "vehicle_positions_dlq" {
  name                       = "${local.name_prefix}-vehicle-positions-dlq"
  message_retention_duration = "604800s"
  labels                     = local.common_labels
}

resource "google_pubsub_subscription" "subscriber" {
  name  = "${local.name_prefix}-subscriber"
  topic = google_pubsub_topic.vehicle_positions.id

  # Push vs pull: pull is the default and works well with Cloud Run for
  # idempotent processing. Switch to push (with auth) if you find yourself
  # paying for idle subscriber instances.
  ack_deadline_seconds = 30

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.vehicle_positions_dlq.id
    max_delivery_attempts = 5
  }

  labels = local.common_labels
}
