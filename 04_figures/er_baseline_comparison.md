# B2 baseline ER comparison record

**Owner:** B (Zhang Yijie)  
**Date:** 2026-10-23  
**Status:** B2 completed; B3 and B4 remain separate decisions.

## Scope

The diagram in `04_figures/er_baseline.drawio` redraws the teacher's Topic 5 five-entity baseline. RideAustin is the group's selected dataset; its field mapping belongs to B3/B4 and does not change this baseline.

## Item-by-item comparison with teacher Topic 5

| Check | Teacher Figure 5 / Listing 17 | B2 diagram | Result |
|---|---|---|---|
| Core entities | Passenger, Driver, Vehicle, Trip, Payment | All five shown | Pass |
| Attributes | Figure 5 fields plus `Trip.start_time` in Listing 17 | All Listing 17 fields shown | Pass |
| Primary keys | `psg_id`, `driver_id`, `vehicle_id`, `trip_id`, `pay_id` | Italic, labelled PK | Pass |
| Foreign keys | `Trip.psg_id`, `Trip.driver_id`, `Driver.vehicle_id`, `Payment.trip_id` | Asterisk and FK shown | Pass |
| Passenger to Trip | 1:N | 1:N | Pass |
| Driver to Trip | 1:N | N:1 when read Trip to Driver | Pass |
| Vehicle to Driver | Figure 5 labels 1:N | 1:N conceptual label | Pass, with SQL caveat below |
| Trip to Payment | Figure 5 labels 1:1 | 1:1 conceptual label | Pass, with SQL caveat below |
| N:M relationships | None in teacher baseline | None | Pass |

## SQL constraint caveats to retain for B4

1. `Driver.vehicle_id` is `NOT NULL UNIQUE`. Each Driver must reference one Vehicle, but each Vehicle can be referenced by at most one Driver. The executable schema therefore permits Vehicle to Driver **0..1**, despite the teacher's conceptual 1:N label. The SQL should not be described as enforcing N:1 unless the unique constraint is removed, which the group has agreed not to do to the official baseline.
2. `Payment.trip_id` is `NOT NULL UNIQUE` and a foreign key. Each Payment belongs to exactly one Trip; each Trip has **0..1 Payment** rows. This is consistent with the teacher's Q2, which explicitly finds completed Trips without Payment. The teacher's 1:1 label describes the intended matched pair, not mandatory payment for every Trip.
3. `Driver.vehicle_id` and `Payment.trip_id` are unique foreign keys. Uniqueness constrains the maximum number of referencing rows; it does not guarantee a referencing row exists.

## Handoff

- A: use the five-entity diagram for A8 review; resolve the two conceptual-versus-SQL cardinality descriptions in the report.
- C: preserve the teacher's five-table DDL in the build script; use the actual SQL constraints when implementing B4 extensions.
- B: carry these caveats into the B4 data dictionary and ER v1.0; do not mark B4 complete on the basis of this B2 deliverable.
