-- top 10 driver-days by total listed fare
SELECT driver_id,
       DATE(start_time) AS income_date,
       ROUND(SUM(fare), 2) AS total_fare
FROM Trip
WHERE status = 'completed'
GROUP BY driver_id, DATE(start_time)
ORDER BY total_fare DESC
LIMIT 10;
