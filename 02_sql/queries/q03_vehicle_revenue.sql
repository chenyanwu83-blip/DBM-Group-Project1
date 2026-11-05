-- total fare per vehicle across all trips
SELECT v.plate,
       ROUND(SUM(t.fare), 2) AS total_fare,
       COUNT(*) AS trip_cnt
FROM Vehicle v
     INNER JOIN Driver d ON d.vehicle_id = v.vehicle_id
     INNER JOIN Trip   t ON t.driver_id  = d.driver_id
GROUP BY v.vehicle_id, v.plate
ORDER BY total_fare DESC;