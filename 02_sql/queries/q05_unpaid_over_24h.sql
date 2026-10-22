-- Completed Trips Unpaid for Over 24 Hours (anti-join + time filter)
SELECT t.trip_id,
       t.driver_id,
       t.fare,
       t.start_time,
       TIMESTAMPDIFF(HOUR, t.start_time, NOW()) AS hours_unpaid
FROM Trip t
WHERE t.status = 'completed'
      AND t.start_time < NOW() - INTERVAL 24 HOUR
      AND NOT EXISTS (SELECT 1 FROM Payment p WHERE p.trip_id = t.trip_id)
ORDER BY hours_unpaid DESC;