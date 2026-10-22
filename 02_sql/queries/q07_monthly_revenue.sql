-- Monthly Revenue Trend (join + monthly GROUP BY)
SELECT DATE_FORMAT(t.start_time, '%Y-%m') AS ym,
       COUNT(*) AS paid_trips,
       ROUND(SUM(p.amount), 2) AS revenue
FROM Trip t
     INNER JOIN Payment p ON p.trip_id = t.trip_id
GROUP BY DATE_FORMAT(t.start_time, '%Y-%m')
ORDER BY ym;