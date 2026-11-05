-- Hot zones: accepted trips per pickup zone
-- Counts all trips (including cancelled after dispatch) per zone.
-- Note: this shows where trips were accepted, not where drivers are scarce.
SELECT z.zone_id,
       z.name,
       COUNT(*) AS accepted_trips          -- 已接单口径：含接单后取消的行
FROM   Trip t
       JOIN trip_detail td ON td.trip_id = t.trip_id
       JOIN pickup_zone z  ON z.zone_id   = td.zone_id
GROUP  BY z.zone_id, z.name
ORDER  BY accepted_trips DESC
LIMIT  15;
