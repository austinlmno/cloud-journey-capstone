# scheduler.tf
# Cloud Scheduler trigger for the poller.
#
# Polling every 30 seconds is aggressive enough to capture vehicle movement
# meaningfully, but well within MBTA's rate limits. Bump this up if you're
# burning Free Tier credits faster than expected.

resource "google_service_account" "scheduler_invoker" {
  account_id   = "${local.name_prefix}-scheduler"
  display_name = "Cloud Scheduler invoker for poller job"
  description  = "Identity used by Cloud Scheduler to invoke the poller Cloud Run job."
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project  = google_cloud_run_v2_job.poller.project
  location = google_cloud_run_v2_job.poller.location
  name     = google_cloud_run_v2_job.poller.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_invoker.email}"
}

resource "google_cloud_scheduler_job" "poll_feed" {
  name        = "${local.name_prefix}-poll-feed"
  description = "Invokes the MBTA GTFS-RT poller every 30 seconds."
  schedule    = "* * * * *" # Every minute; 30s requires a second job offset by 30s.
  time_zone   = "UTC"
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.poller.name}:run"

    oauth_token {
      service_account_email = google_service_account.scheduler_invoker.email
    }
  }

  depends_on = [google_project_service.enabled_apis]
}
