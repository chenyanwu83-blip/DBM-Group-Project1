-- hours with at least 2000 trips
SELECT HOUR(start_time) AS hr,
       COUNT(*) AS trips
FROM Trip
GROUP BY HOUR(start_time)
HAVING COUNT(*) >= 2000
ORDER BY trips DESC;