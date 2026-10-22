-- Completed Trips with Their Payments (1:1 join)
SELECT t.trip_id,
       t.psg_id,
       t.driver_id,
       t.fare,
       p.pay_id,
       p.amount,
       p.method
FROM Trip t
     INNER JOIN Payment p ON p.trip_id = t.trip_id
WHERE t.status = 'completed'
ORDER BY t.start_time DESC;