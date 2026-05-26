# ADR-0002: Project Architecture

- **Status:** Accepted
- **Date:** 2026-05-25
- **Deciders:** Austin
- **Phase:** Phase 1

## Context

As I start my cloud training I will be working on my capstone as I go. The Terraform structure outlined here will serve as the structure for the project. The layered approach is modeled after the Google terraform-example-foundation, which organizes infrastructure provisioning in dependency order — each layer depends on the one above it and provides inputs to the one below.

## Decision

Below is the Terraform structure I've established.

- **0-bootstrap** — remote state setup: GCS bucket for Terraform state, and a service account for Terraform to run as.
- **1-org** — stub; minimal work here as I won't have org-level policies to manage in a personal project context.
- **2-environments** — dev and prod environments, each parameterized via separate `.tfvars` files against shared modules.
- **3-networks** — VPC, subnets, firewall rules, Cloud NAT, and potentially VPN stubs for hybrid connectivity elements. Things that must exist before any application does.
- **4-projects** — the MBTA (Massachusetts Bay Transportation Authority) project: project creation, API enablement, IAM bindings, and service accounts. The container everything runs in.
- **5-app-infra** — workloads: Cloud Run services, Pub/Sub topics and subscriptions, BigQuery datasets, Dataflow jobs, Cloud Storage buckets, Cloud Scheduler jobs. Everything that constitutes the actual system.

## Alternatives Considered

**Flat Terraform layout:** A single directory with all resources defined together. Simpler to start, faster to first deploy, but provides no separation of concerns and becomes hard to reason about as the project grows. Doesn't demonstrate the dependency-ordering discipline that enterprise GCP patterns require.

**Terragrunt:** Adds a wrapper layer to manage module instantiation across environments. More powerful but introduces another tool and learning curve on top of an already multi-phase project. Not warranted at this scale.

**One environment instead of two:** Simpler, but omits the environment separation pattern entirely. Dev and prod together demonstrate parameterized module reuse, which is a meaningful portfolio signal.

**Eliminating 1-org entirely:** Viable. Kept as a stub to preserve the layer numbering and to document that org-level policy management is intentionally out of scope rather than overlooked.

## Consequences

**Positive:**

- Establishes a dependency-ordered provisioning model that mirrors enterprise GCP patterns, making the capstone structurally credible as a portfolio artifact.
- Environment separation via shared modules and separate `.tfvars` files demonstrates parameterized reuse without duplicating code.
- Reduces scope creep: each layer has a defined boundary, making it easier to reason about what belongs where.
- Unblocks next steps: build the poller in Cloud Run, wire Cloud Scheduler, configure the Cloud Storage lifecycle policy, and complete ADR-0003 (storage tiering).

**Negative or accepted trade-offs:**

- **What you give up:** simplicity and faster time-to-first-deployment. A flat layout would be running sooner.
- **What becomes harder:** onboarding someone new to the repo takes longer; debugging a Terraform error requires understanding which layer it originates in.
- **What to revisit:** whether this structure remains the right fit as scope grows through Phases 2–5.

**Things to watch:**

- Data flow validation: if telemetry doesn't move cleanly through the pipeline as intended, the layer boundaries may be obscuring a misconfigured dependency.
- Cost discipline: dev environment only during active development; prod provisioned minimally or documented as a deploy target to avoid unnecessary GCP spend.
- Generalizability: a future test of this architecture is whether it can accommodate King County Metro data — a different telemetry schema and operational domain, but the same architectural pattern. If it can't adapt without structural changes, that's a signal the design is too tightly coupled to the MBTA domain.

## References

- [terraform-example-foundation / 0-bootstrap](https://github.com/terraform-google-modules/terraform-example-foundation/tree/main/0-bootstrap) — primary reference for layer structure and bootstrap patterns. Established that remote state and a dedicated Terraform service account belong at layer 0, separate from org and environment concerns.
- **Study plan connection:** Phase 1, Week 4. Terraform becomes central in Phase 2 onward; this structure is established early so the capstone has a consistent home from the start.
- **Related ADRs:** ADR-0003 (storage tiering) — next decision downstream of this one.
