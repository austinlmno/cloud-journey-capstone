# budget.tf
# Budget alerts — the single most important configuration for a new GCP project.
#
# Phase 1 Technical Requirements explicitly calls this out as the day-1 config
# to set. Done in Terraform here so a fresh clone of the repo includes it
# automatically.
#
# Note: budgets require a billing account ID, which you get from the GCP
# console. It's intentionally not in variables.tf as a default — set it in a
# terraform.tfvars file that's gitignored.

variable "billing_account_id" {
  description = "Billing account ID for budget alerts. Find this in the GCP console under Billing."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly budget ceiling. Alerts fire at percentages of this value."
  type        = number
  default     = 50
}

resource "google_billing_budget" "study_project" {
  billing_account = var.billing_account_id
  display_name    = "Transit telemetry — ${var.environment}"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  # Alert at 50%, 90%, 100%, and 120% of budget. The 120% threshold catches
  # the case where a runaway job spends faster than alerts fire.
  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.2
  }

  # Email notifications go to the billing account's notification channels by
  # default. Add a monitoring notification channel here to route alerts
  # elsewhere (e.g., to a personal email separate from the billing contact).
}
