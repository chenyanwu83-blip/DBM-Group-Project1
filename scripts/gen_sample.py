import random
from datetime import datetime, timedelta
from faker import Faker
from sqlalchemy import create_engine, text

fake = Faker()
Faker.seed(42); random.seed(42)          # 固定seed：每次生成完全一致
engine = create_engine("mysql+pymysql://root:cds534pass@localhost:3306/ride_hailing")

N_PSG, N_DRV, N_TRIP = 1000, 50, 5000
t0 = datetime(2026, 7, 1)

with engine.begin() as c:
    c.execute(text("SET FOREIGN_KEY_CHECKS=0"))
    for t in ("Payment","Trip","Driver","Vehicle","Passenger"):
        c.execute(text(f"TRUNCATE TABLE {t}"))
    c.execute(text("SET FOREIGN_KEY_CHECKS=1"))

    c.execute(text("INSERT INTO Passenger (psg_id,name) VALUES (:i,:n)"),
               [{"i":i,"n":fake.name()} for i in range(1,N_PSG+1)])
    c.execute(text("INSERT INTO Vehicle (vehicle_id,plate) VALUES (:i,:p)"),
               [{"i":i,"p":fake.license_plate()} for i in range(1,N_DRV+1)])
    c.execute(text("INSERT INTO Driver (driver_id,name,vehicle_id) VALUES (:i,:n,:v)"),
               [{"i":i,"n":fake.name(),"v":i} for i in range(1,N_DRV+1)])

    trips = [{"i":i,
              "p":random.randint(1,N_PSG),
              "d":random.randint(1,N_DRV),
              "f":round(random.uniform(8,120),2),
              "s":random.choices(["completed","canceled","ongoing"],[0.85,0.10,0.05])[0],
              "t":(t0+timedelta(minutes=random.randint(0,60*24*110))).strftime("%Y-%m-%d %H:%M:%S")}
             for i in range(1,N_TRIP+1)]
    c.execute(text("""INSERT INTO Trip (trip_id,psg_id,driver_id,fare,status,start_time)
                      VALUES (:i,:p,:d,:f,:s,:t)"""), trips)

    pays, pid = [], 1
    for t in trips:                        # completed 的 95% 有支付 → 留 5% 给反连接
        if t["s"]=="completed" and random.random()<0.95:
            pays.append({"pid":pid,"tid":t["i"],"a":t["f"],
                         "m":random.choices(["card","wallet","cash"],[0.6,0.3,0.1])[0]}); pid+=1
    c.execute(text("""INSERT INTO Payment (pay_id,trip_id,amount,method)
                      VALUES (:pid,:tid,:a,:m)"""), pays)

print(f"done: {N_PSG} passengers / {N_DRV} drivers / {N_TRIP} trips / {len(pays)} payments")