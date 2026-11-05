-- Service tier vs rating: completed trips only
-- COUNT(rating) skips NULLs so it gives the coverage rate;
-- AVG(rating) also ignores NULL automatically.
SELECT st.name                      AS tier,
       COUNT(*)                     AS completed_trips,
       ROUND(AVG(t.fare), 2)        AS avg_fare,
       COUNT(td.rating)             AS rated_trips,
       ROUND(COUNT(td.rating) / COUNT(*) * 100, 1) AS rating_cov_pct,
       ROUND(AVG(td.rating), 2)     AS avg_rating   -- AVG 自动忽略 NULL
FROM   Trip t
       JOIN trip_detail td    ON td.trip_id = t.trip_id
       JOIN service_tier st   ON st.tier_id = td.service_tier_id
WHERE  t.status = 'completed'
GROUP  BY st.tier_id, st.name
ORDER  BY completed_trips DESC;
