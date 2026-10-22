-- Repeat Passengers (COUNT DISTINCT + HAVING)
SELECT p.psg_id,
       p.name,
       COUNT(*) AS total_trips,
       COUNT(DISTINCT DATE(t.start_time)) AS active_days
FROM Passenger p
     INNER JOIN Trip t ON t.psg_id = p.psg_id
GROUP BY p.psg_id, p.name
HAVING COUNT(DISTINCT DATE(t.start_time)) >= 2
ORDER BY active_days DESC, total_trips DESC;