# Transit Telemetry

A long-running portfolio project that ingests, processes, and analyzes public
transit telemetry from the MBTA GTFS-Realtime feed. This is the capstone
project that grows across all phases of a multi-year GCP / Azure solutions
architect study plan.

## Current phase

**Phase 1 — Cloud & GCP Foundations.** The current v0 architecture is the
minimum viable pipeline that exercises every Phase 1 domain (compute, storage,
networking, IAM, Pub/Sub, BigQuery, operations) on a single coherent system.

```
[Cloud Scheduler]
       |
       v
[Cloud Run Job: poller]  ---fetches--->  MBTA GTFS-RT feed
       |
       v
[Pub/Sub topic: vehicle-positions]
       |
       v
[Cloud Run Service: subscriber]
       |
       v
[Cloud Storage: raw JSON, partitioned by date]
       |
       v
[Scheduled BigQuery load]
       |
       v
[BigQuery: partitioned + clustered table]
       |
       v
[Looker Studio dashboard]
```

Future phases will replace the Cloud Run subscriber with a Dataflow streaming
pipeline (Phase 2), mirror one layer in Microsoft Fabric (Phase 3), add a
Vertex AI anomaly detection model (Phase 4), and layer in a RAG system plus
agentic incident triage (Phase 5). See `docs/adr/` for the decision history.

## Repository layout

```
.
├── README.md
├── docs/
│   └── adr/                    Architecture decision records.
├── terraform/                  All infrastructure as code.
├── services/
│   ├── poller/                 Cloud Run job: fetch GTFS-RT, publish to Pub/Sub.
│   └── subscriber/             Cloud Run service: Pub/Sub -> Cloud Storage.
└── sql/
    └── bigquery/               Schema and load SQL.
```

## Setup

This project requires the following day-1 setup, in this order:

1. **Personal GCP project.** Use a dedicated project, not your default one.
   Note the project ID and the billing account ID — Terraform needs both.
2. **MBTA API key.** Register at https://api-v3.mbta.com/. Store it in Secret
   Manager as `mbta-api-key` (the name is configurable in `variables.tf`).
3. **Terraform variables.** Copy `terraform.tfvars.example` to
   `terraform.tfvars` and fill in `project_id` and `billing_account_id`.
   `terraform.tfvars` is gitignored.
4. **First apply.** Run `terraform apply --target=google_artifact_registry_repository.services`
   first to create the container repo, then build and push the poller and
   subscriber images, then run a full `terraform apply`.

## Study-plan reference

Each Terraform file is annotated with the Phase 1 week(s) it exercises. The
README of each `services/` subdirectory documents what the code is doing and
why. The `docs/adr/` folder is the most important part of the repo — every
non-trivial decision gets an ADR, and the accumulated history is what
distinguishes a study project from a portfolio piece.
