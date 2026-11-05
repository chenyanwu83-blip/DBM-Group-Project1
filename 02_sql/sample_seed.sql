USE ride_hailing;

INSERT INTO Passenger (psg_id, name) VALUES
 (1,'王小明'),(2,'李小红'),(3,'张大力'),(4,'陈静'),(5,'刘洋'),(6,'赵敏');

INSERT INTO Vehicle (vehicle_id, plate) VALUES
 (1,'沪A12345'),(2,'沪B67890'),(3,'沪C24680'),(4,'沪D13579'),(5,'沪E11223');

INSERT INTO Driver (driver_id, name, vehicle_id) VALUES
 (1,'周师傅',1),(2,'吴师傅',2),(3,'郑师傅',3),(4,'冯师傅',4),(5,'褚师傅',5);

INSERT INTO Trip (trip_id, psg_id, driver_id, fare, status, start_time) VALUES
 (1, 1,1, 35.50,'completed','2026-10-18 08:12:00'),
 (2, 2,1, 18.00,'completed','2026-10-18 09:40:00'),
 (3, 1,2, 62.30,'completed','2026-10-18 14:05:00'),
 (4, 3,2, 27.80,'completed','2026-10-19 07:55:00'),
 (5, 4,3, 45.00,'completed','2026-10-19 19:30:00'),
 (6, 2,3, 12.50,'canceled', '2026-10-19 20:10:00'),
 (7, 5,4, 88.00,'completed','2026-10-20 06:45:00'),
 (8, 1,4, 22.40,'completed','2026-10-20 11:20:00'),
 (9, 6,5, 55.60,'completed','2026-10-20 16:00:00'),
 (10,3,5, 30.00,'completed','2026-10-21 09:15:00'),
 (11,4,1, 40.20,'completed','2026-10-21 22:30:00'),
 (12,5,2, 95.00,'completed','2026-10-22 05:50:00');

INSERT INTO Payment (pay_id, trip_id, amount, method) VALUES
 (1, 1, 35.50,'card'),(2, 2, 18.00,'wallet'),(3, 3, 62.30,'card'),
 (4, 5, 45.00,'cash'),(5, 7, 88.00,'card'),(6, 9, 55.60,'wallet'),
 (7,10, 30.00,'card'),(8,12, 95.00,'card'),(9, 8, 22.40,'cash');
-- 未支付：trip 4、6(已取消,无需支付)、11 → NOT EXISTS 查询能查出司机2、1