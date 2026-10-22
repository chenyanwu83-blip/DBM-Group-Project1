-- Driver Daily Income Ranking (window function RANK)
SELECT driver_id,
       income_date,
       day_income,
       RANK() OVER (ORDER BY day_income DESC) AS rnk
FROM (SELECT driver_id,
              DATE(start_time) AS income_date,
              ROUND(SUM(fare), 2) AS day_income
       FROM Trip
       WHERE status = 'completed'
       GROUP BY driver_id, DATE(start_time)) AS daily
ORDER BY rnk
LIMIT 10;
