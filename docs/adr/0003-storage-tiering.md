# ADR-0003: Storage Tiering

- **Status:** Accepted
- **Date:** 2026-05-28
- **Deciders:** Austin
- **Phase:** Phase 1

## Context

The data received from the MBTA API has be be stored so for later use. The storage decisions made in this document will dictate lines of demarcation as well as the life cycle for raw, processed, and reference data, partitioning, and access patterns.

## Decision

Below are the bucket tiers I've established with their life-cycles:

- **raw data** — unmodified JSON from the poller, partitioned by date. Standard → Nearline at 30 days → Coldline at 90 days → delete at 365 days. Retained longest because it's irreplaceable.
- **processed data** — parsed, cleaned, possibly joined data before or after it hits BigQuery. Standard → Nearline at 30 days → delete at 90 days. Shorter retention because it's reproducible from raw.
- **reference data** — static or slowly-changing data you'd join against (MBTA route definitions, stop locations, etc.) Standard indefinitely, versioning enabled. Different character from pipeline data — slowly changing, frequently read, historically significant.


## Alternatives Considered

- **Memorystore/Redis:** Integrate their use for caching. Rejected because application does not require low latency nor consistent referencing of data.
- **NoSQL:** Use NoSQL to store all of the data from the poller. Rejected because NoSQL is optimized for low-latency random access by key, which my access pattern doesn't need.
- **Longer Processed Data Lifecycle:** Processed data to have life-cycle of Standard → Nearline at 30 days → Coldline at 90 days → delete at 365 days. Rejected because the raw data will act as a safety net and can be processed into processed data.

## Consequences

What follows from this decision? Both intended and unintended.

**Positive:**

- What you gain: Clarity on the storage model enables me establish the basis for latency and batch retieval of data.
- What becomes easier downstream: Create cost models based on storage life of the data. Creates a foundation for scaling this in future iterations by enabling the basics now.
- What this unblocks: Creation of the poller and scheduler, and provisioning the cloud storage buckets.

**Negative or accepted trade-offs:**

- What you give up: The ability to continously stream data and operate with limited latency. The application won't be able to be used for real-time applications.
- What becomes harder: The feedback loop of finding inconsistencies, issues, or anomalies becomes a longer process because of the batch nature of the data storage.
- What you'll need to revisit later: How do I scale and create a more real-time low-latency application using the overarching framework? I'd like to know how easy or difficult it is to change our parts of the application and enhance its capabilities.

**Things to watch:**

- Signals that would tell you the decision was wrong: I'll look for how much latency I've generated with this storage model and how efficiently I can turn raw data to processed data to justify the data life cycle choices.
- Cost, performance, or operational thresholds worth monitoring: I'll work to get an idea of the active running cost as compared to just the storage cost.
- A specific future phase or milestone that might force a revisit: I would like to take a look at scaling this in the future. Data in real-time offers increase ability to identify and correct mistakes. 

## References

- [Link to ADR-0002] (/Users/austinlmno/Documents/GitHub/cloud-journey-capstone/docs/adr/learning_log_template.md) (project structure informs where these buckets live)
- GCP Cloud Storage lifecycle documentation
- GCP storage tiers pricing page