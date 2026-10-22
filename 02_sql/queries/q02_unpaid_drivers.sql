-- Drivers with Completed but Unpaid Trips (NOT EXISTS anti-join)
SELECT DISTINCT
       d.driver_id,
       d.name
FROM Driver d
     INNER JOIN Trip t ON t.driver_id = d.driver_id
WHERE t.status = 'completed'
      AND NOT EXISTS (SELECT 1
                       FROM Payment p
                       WHERE p.trip_id = t.trip_id)
ORDER BY d.driver_id;