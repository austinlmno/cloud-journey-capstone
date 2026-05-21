# ADR-0001: Use MBTA GTFS-Realtime as the project's data source

- **Status:** Accepted
- **Date:** 2026-05-21
- **Deciders:** Austin
- **Phase:** Phase 1 — Cloud & GCP Foundations

## Context

This project is the long-running portfolio piece that will grow across all five
phases of the Solutions Architect study plan, eventually demonstrating data
architecture, ML platform work, and AI application architecture on a single
coherent domain.

Three constraints shaped the choice of domain:

1. **Independence from employer.** The project needs to be publishable on a
   personal GitHub repo without IP ambiguity. That rules out anything modeled
   directly on Symbotic's robotics telemetry, even if the patterns transfer.
2. **Telemetry-shaped data.** The plan's architectural muscles — partitioning,
   clustering, streaming windows, time-series storage, anomaly detection — only
   develop if the data has high volume, time-series shape, and multiple entity
   types with plausible anomalies.
3. **Real data over simulated.** A live feed removes the "is my simulator
   realistic?" doubt and forces real ingestion engineering (rate limits,
   schema drift, network failures, late-arriving data).

Public transit GTFS-Realtime feeds fit all three. Major agencies publish vehicle
positions, trip updates, and service alerts as Protobuf feeds over HTTP, free
to use with light registration. Among the well-documented options (MBTA, BART,
TfL, SF Muni), MBTA stood out for feed quality and rate-limit headroom.

## Decision

> We will use the MBTA GTFS-Realtime vehicle-positions feed as the primary
> data source for the project, polled at 30-second intervals during initial
> development.

The trip-updates and service-alerts feeds will be added later if useful, but
the vehicle-positions feed alone provides enough volume and shape to exercise
every Phase 1 service.

## Alternatives Considered

- **Simulated robotics telemetry.** Closest to Symbotic's domain and the
  obvious first instinct. Rejected because the simulator becomes a moving part
  to maintain, and the IP-adjacency creates ambiguity for a public repo.
- **Energy / smart-meter data (UK-DALE, Pecan Street).** Real public datasets
  with clean time-series shape. Rejected because the data is historical rather
  than live — loses the real ingestion engineering, which is half the value.
- **NOAA weather stations.** Real and live, but anomalies are less interesting
  and the "operational stakes" framing doesn't carry through to the agent
  scenarios in Phase 5.
- **Simulated e-commerce clickstream.** Event-driven rather than continuous
  telemetry. Loses the time-series-at-scale flavor that makes Bigtable and
  windowed aggregations worth reaching for.
- **Other transit agencies (BART, TfL, SF Muni).** All viable. MBTA chosen on
  the strength of its docs, the generous rate limits, and the volume of vehicles
  during peak service hours.

## Consequences

**Positive:**

- Real public data means a public repo is unambiguous.
- The data shape — many vehicles, frequent updates, route/trip/stop hierarchy —
  exercises partitioning, clustering, and entity modeling decisions naturally.
- A map-based dashboard at the end will be more compelling in interviews than
  rows of synthetic device IDs.
- The domain is generally legible; reviewers don't need warehouse-robotics
  context to understand the system.

**Negative or accepted trade-offs:**

- Less Symbotic-relevant on its face. Mitigated by the fact that the
  architectural patterns (high-volume time-series telemetry, streaming
  aggregations, anomaly detection) transfer cleanly regardless of domain.
- Dependent on MBTA's feed availability. If the feed changes format or goes
  down, the project breaks. Acceptable risk for a study project; would not be
  acceptable for production.
- Protobuf parsing adds a small amount of complexity vs. a JSON-native source.

**Things to watch:**

- Rate-limit behavior at 30-second polling — if MBTA tightens limits, adjust
  cadence before re-architecting.
- Schema or endpoint changes from MBTA's developer portal.
- Whether trip-updates or service-alerts feeds become useful enough to add as
  separate streams in Phase 2.

## References

- MBTA developer portal: https://www.mbta.com/developers/v3-api
- GTFS-Realtime spec: https://gtfs.org/realtime/
- Study plan Phase 1, Resource Guide section on Free Tier discipline
- Conversation context: domain-selection decision, May 2026
