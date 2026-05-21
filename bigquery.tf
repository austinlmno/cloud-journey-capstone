# bigquery.tf
# Analytics layer — partitioned and clustered table for vehicle positions.
#
# Phase 1 reference: weeks 7-8 (BigQuery deep dive — partitioning, clustering,
# slot management). This file is the single most directly study-relevant piece
# of the project.
#
# Design decisions worth their own ADR:
# - Partition by ingestion date (_PARTITIONTIME). Simple, predictable cost
#   profile. An alternative is partitioning on the event's `timestamp` field,
#   which makes time-range queries cheaper but creates more partitions to
#   manage. ADR-0003 should document this choice.
# - Cluster on route_id and vehicle_id. Most queries filter on one or both.
# - Schema is a starting point; expect to evolve as new feed fields prove useful.

resource "google_bigquery_dataset" "transit" {
  dataset_id    = replace("${local.name_prefix}_telemetry", "-", "_")
  friendly_name = "Transit telemetry"
  description   = "GTFS-Realtime vehicle positions ingested from MBTA."
  location      = "US" # Multi-region for query flexibility; cost is similar at this scale.

  default_table_expiration_ms = null # Tables persist by default; partition expiry handles retention.

  labels = local.common_labels

  depends_on = [google_project_service.enabled_apis]
}

resource "google_bigquery_table" "vehicle_positions" {
  dataset_id = google_bigquery_dataset.transit.dataset_id
  table_id   = "vehicle_positions"

  description = "GTFS-Realtime vehicle positions, one row per position update. Partitioned by ingestion date, clustered by route_id and vehicle_id."

  time_partitioning {
    type                     = "DAY"
    field                    = "event_timestamp" # Event-time partitioning. See ADR-0003.
    require_partition_filter = true              # Forces queries to include a partition filter — prevents accidental full-table scans.
    expiration_ms            = 1000 * 60 * 60 * 24 * 365 # 365 days
  }

  clustering = ["route_id", "vehicle_id"]

  schema = jsonencode([
    {
      name        = "event_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp from the GTFS-RT VehiclePosition message."
    },
    {
      name        = "ingest_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "When the subscriber wrote this record to GCS. Useful for measuring end-to-end latency."
    },
    {
      name        = "vehicle_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Stable identifier for the vehicle."
    },
    {
      name        = "trip_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Trip the vehicle is currently servicing, if known."
    },
    {
      name        = "route_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Route the vehicle is currently servicing, if known."
    },
    {
      name        = "latitude"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "WGS84 latitude."
    },
    {
      name        = "longitude"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "WGS84 longitude."
    },
    {
      name        = "bearing"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Direction of travel in degrees, 0 = north."
    },
    {
      name        = "speed_mps"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Reported speed in meters per second."
    },
    {
      name        = "current_status"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "INCOMING_AT | STOPPED_AT | IN_TRANSIT_TO per GTFS-RT spec."
    },
    {
      name        = "current_stop_sequence"
      type        = "INT64"
      mode        = "NULLABLE"
      description = "Stop sequence number along the trip."
    },
  ])

  labels = local.common_labels
}
