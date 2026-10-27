#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
import_data.py — CDS534 Topic 5 样本数据生成器（C4 交付件，2026-10-25）
=====================================================================

数据路线（D-10 定稿 v1.1）：Python 固定 seed 生成器 + RideAustin 真实数据标定。
分布参数依据（决策登记见 01_docs/design_decisions.md）：

  - A4 §三 v1.2.1（01_docs/a4_dataset_decision.md）：
    行数与占比、四档费率、评分覆盖率 90.7%（生成取 90%，D-11②）、
    支付方式 balance/cash/card ≈ 45/30/25（真实数据无此字段，A3 假设）
  - D-06 v1.2：接单后 3 分钟宽限期——免费取消 fare=NULL 无 Payment；
    收费取消 fare=USD 1.5 且恰一条 Payment(amount=1.5)；全程美元
  - D-05：status 只用 completed/canceled/accepted/en_route（无 requested）
  - D-11：①上车区位约 15 区、top3≈35%（课程设定，无真实标定源）
           ②档次占比 REGULAR≈95.1%（含 0.1% HONDA 脏值归并）/SUV 3.7/
             PREMIUM 0.9/LUXURY 0.3；评分仅 completed、AVG 忽略 NULL
  - 实测档案 v1.1 勘误（01_docs/a4_rideaustin_profile.md，commit 3729f4d）：
    total_fare = 计价核心 + $1.6–1.7 固定附加费（本生成器取 1.65）、
    不含 tip/free_credit/round_up；surge 不做乘法还原（生成器不建模 surge）
  - D-12：RIDE_ID 哈希 80/20 拆标定/留出集。本脚本常量 = A4 已发布的
    全量实测值（训练段重算值"与全量几乎不动"，A 交付后仅改本文件常量区）

可复现性（D-08③ 数据同源）：只用标准库 random + 固定 seed=534，
  **不使用 faker**（版本漂移会破坏五机逐行一致）；姓名/车牌由内置表生成。
  五台机器任何 Python 3.10+ 跑出的 data_import.sql 逐字节一致。

用法：
  python3 02_sql/import_data.py                # 生成 02_sql/data_import.sql + 自验
  python3 02_sql/import_data.py --load         # 生成后直接写入本机 MySQL（需 pymysql）
  mysql -u root -p < 02_sql/build.sql          # 先建库（含扩展表与维度 seed）
  mysql -u root -p < 02_sql/data_import.sql    # 或手动导入生成的 SQL 文件

验收三条（A4 §四）由脚本生成后自动断言：
  ① canceled 行：免费取消 fare=NULL 且无 Payment；收费取消 fare=1.5 且恰 1 条 Payment
  ② status 取值仅 completed / canceled / accepted / en_route
  ③ Payment.method 取值仅 balance / cash / card
另附 C3 扩展表不变量：每 Trip 恰一行 trip_detail；rating 仅 completed 行非空。
"""
import argparse
import math
import random
import sys
from datetime import datetime, timedelta

# ──────────────────────────────────────────────────────────────
# 常量区（标定参数——改动只应发生在这里，来源见文件头）
# ──────────────────────────────────────────────────────────────
SEED = 534

# 行数（A4 §三：Trip ≥ 5 万行的 M2 硬指标，取 60,000）
N_PSG, N_DRV, N_VEH, N_TRIP = 3_000, 150, 150, 60_000

# status 构成（精确行数）：completed 82% / canceled 10% / accepted+en_route 8%
N_COMPLETED = 49_200
N_CANCELED = 6_000
N_ACCEPTED, N_EN_ROUTE = 2_400, 2_400
assert N_COMPLETED + N_CANCELED + N_ACCEPTED + N_EN_ROUTE == N_TRIP

# D-06 v1.2：取消两类结果拆分（收费取消约 60% / 免费取消约 40%）
P_CHARGED_CANCEL = 0.60
CANCEL_FEE = 1.50                      # USD（= REGULAR 档基础价，D-06 v1.2）

# completed 中留约 3% 未支付（官方 Q2 反连接非空可截图）
P_COMPLETED_PAID = 0.97

# 支付方式占比（A3 假设，真实数据无此字段）
METHODS = ["balance", "cash", "card"]
METHOD_W = [0.45, 0.30, 0.25]

# 四档费率（A4 §三 v1.2 实测，美元；REGULAR 含平台真实调价两期）
#   tier_id: (name, base, per_minute, per_mile 或 [(rate, p), ...])
TIERS = {
    1: ("REGULAR", 1.5, 0.25, [(0.99, 0.8), (1.50, 0.2)]),   # 新费率占比 0.2 为拟合均值口径
    2: ("SUV", 3.0, 0.35, [(2.60, 1.0)]),
    3: ("PREMIUM", 3.0, 0.40, [(2.75, 1.0)]),
    4: ("LUXURY", 5.0, 0.50, [(3.75, 1.0)]),
}
FIXED_FEE = 1.65                       # 实测档案 v1.1：total_fare 含 $1.6–1.7 固定附加费
FARE_MEAN_TARGET = 13.99               # total_fare 全量均值（对照参考，不强制精确命中）

# 档次构成（精确行数，D-11②；REGULAR 95.1% = 95.0% + 0.1% HONDA 脏值归并）
TIER_N = {1: 57_060, 2: 2_220, 3: 540, 4: 180}          # 95.1/3.7/0.9/0.3 %
assert sum(TIER_N.values()) == N_TRIP

# 上车区位构成（精确行数，D-11① 课程设定：15 区、top3≈35%，参照 TLC 集中度）
N_ZONE = 15
ZONE_N = {1: 7_200, 2: 7_200, 3: 6_600}                  # top3 = 21,000 = 35%
for z in range(4, N_ZONE + 1):
    ZONE_N[z] = 3_250                                     # 其余 12 区各 3,250 = 65%
assert sum(ZONE_N.values()) == N_TRIP

# 评分（D-11②：仅 completed 行、生成覆盖率 90%、1–5 整数；星级分布=A4 §三 有值行口径）
P_RATED = 0.90
STAR_V = [5, 4, 3, 2, 1]
STAR_W = [90.3, 5.5, 2.0, 0.6, 1.7]

# 时间窗与时段分布（课程设定：截至 2026-10-25 的 365 天；
# 17–20 时合计 ≈20%，凌晨低谷使 q06 的 HAVING>=2000 有过滤效果）
T0 = datetime(2025, 10, 26)
N_DAYS = 365
HOUR_W = [1.9, 1.3, 1.0, 1.0, 1.3, 2.4,                    # 0–5
          3.8, 4.8, 5.3, 5.3, 5.3,                          # 6–10
          5.6, 5.6, 5.6, 5.6, 5.6, 5.9,                     # 11–16
          5.0, 5.0, 5.0, 5.0,                               # 17–20（合计 20%）
          4.4, 3.0, 2.6]                                    # 21–23

# 里程/时长（课程拟合：令 completed 均费 ≈ $13.99 的 total_fare 口径）
MILES_MU, MILES_SIGMA = math.log(4.55), 0.55               # 对数正态，均值 ≈5.3 英里
MIN_PER_MILE = 2.5                                         # 市内均速约 24 mph
OVERHEAD_MU, OVERHEAD_SIGMA = math.log(4.0), 0.5           # 接驾/起步开销均值 ≈4.5 分钟

# 姓名内置表（替代 faker：五机逐行一致不依赖第三方库版本）
FIRST = ("James Mary Robert Patricia John Jennifer Michael Linda David Elizabeth "
         "William Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen "
         "Christopher Lisa Daniel Nancy Matthew Betty Anthony Margaret Mark Sandra "
         "Donald Ashley Steven Kimberly Andrew Emily Paul Donna Joshua Michelle "
         "Kenneth Carol Kevin Amanda Brian Dorothy George Melissa Timothy Deborah "
         "Ronald Stephanie Edward Rebecca Jason Sharon Jeffrey Laura Ryan Cynthia "
         "Jacob Kathleen Gary Amy Nicholas Angela Eric Shirley Jonathan Anna "
         "Stephen Brenda Larry Pamela Justin Emma Scott Nicole Brandon Helen "
         "Benjamin Samantha Samuel Katherine Gregory Christine Alexander Debra "
         "Frank Rachel Patrick Carolyn Raymond Janet Jack Maria").split()
LAST = ("Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez "
        "Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin "
        "Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson Walker "
        "Young Allen King Wright Scott Torres Nguyen Hill Flores Green Adams Nelson "
        "Baker Hall Rivera Campbell Mitchell Carter Roberts Gomez Phillips Evans "
        "Turner Diaz Parker Cruz Edwards Collins Reyes Stewart Morris Morales "
        "Murphy Cook Rogers Gutierrez Ortiz Morgan Cooper Peterson Bailey Reed "
        "Kelly Howard Ramos Kim Cox Ward Richardson Watson Brooks Chavez Wood "
        "James Bennett Gray Mendoza Ruiz Hughes Price Alvarez Castillo Sanders "
        "Patel Myers Long Ross Foster Jimenez").split()


# ──────────────────────────────────────────────────────────────
# 生成
# ──────────────────────────────────────────────────────────────
def _exact_pool(counts: dict, rng: random.Random) -> list:
    """{值: 行数} → 精确构成的列表（再洗牌，保证占比分毫不差；必须用播种的 rng）"""
    pool = [v for v, n in counts.items() for _ in range(n)]
    rng.shuffle(pool)
    return pool


def _tier_mile_rate(rng: random.Random, tier_id: int) -> float:
    """REGULAR 按两期占比抽费率，其余档单一费率"""
    rates = TIERS[tier_id][3]
    x, acc = rng.random(), 0.0
    for rate, p in rates:
        acc += p
        if x < acc:
            return rate
    return rates[-1][0]


def generate():
    rng = random.Random(SEED)          # 独立实例：不受调用方全局 random 状态影响

    # 1) Passenger / Vehicle / Driver（官方五表；Driver↔Vehicle 1:1 绑定）
    passengers = [(i, f"{rng.choice(FIRST)} {rng.choice(LAST)}") for i in range(1, N_PSG + 1)]
    plates, used = [], set()
    while len(plates) < N_VEH:         # 车牌唯一（官方 plate UNIQUE）
        p = "TX-" + "".join(rng.choice("ABCDEFGHJKLMNPRSTUVWXYZ") for _ in range(3)) \
            + "".join(rng.choice("0123456789") for _ in range(4))
        if p not in used:
            used.add(p)
            plates.append(p)
    vehicles = [(i, plates[i - 1]) for i in range(1, N_VEH + 1)]
    drivers = [(i, f"{rng.choice(FIRST)} {rng.choice(LAST)}", i) for i in range(1, N_DRV + 1)]

    # 2) 精确构成池：status / 档次 / 区位
    status_pool = _exact_pool({"completed": N_COMPLETED, "canceled": N_CANCELED,
                               "accepted": N_ACCEPTED, "en_route": N_EN_ROUTE}, rng)
    tier_pool = _exact_pool(TIER_N, rng)
    zone_pool = _exact_pool(ZONE_N, rng)

    trips, details = [], []
    for i in range(1, N_TRIP + 1):
        status = status_pool[i - 1]
        tier_id = tier_pool[i - 1]
        zone_id = zone_pool[i - 1]

        # start_time = 派单/INSERT 时刻（D-05），非上车时刻
        day = rng.randrange(N_DAYS)
        hour = rng.choices(range(24), weights=HOUR_W)[0]
        t = T0 + timedelta(days=day, hours=hour,
                           minutes=rng.randrange(60), seconds=rng.randrange(60))

        # 车费（D-06 v1.2 三类结果）
        if status == "completed":
            miles = round(rng.lognormvariate(MILES_MU, MILES_SIGMA), 1)
            minutes = max(3, round(MIN_PER_MILE * miles + rng.lognormvariate(OVERHEAD_MU, OVERHEAD_SIGMA)))
            _, base, per_min, _ = TIERS[tier_id]
            fare = round(base + per_min * minutes + _tier_mile_rate(rng, tier_id) * miles
                         + FIXED_FEE, 2)
        elif status == "canceled" and rng.random() < P_CHARGED_CANCEL:
            fare = CANCEL_FEE           # 收费取消
        else:
            fare = None                 # 免费取消 / accepted / en_route

        # 评分：仅 completed 行、约 90% 有值（D-11②）
        rating = (rng.choices(STAR_V, weights=STAR_W)[0]
                  if status == "completed" and rng.random() < P_RATED else None)

        trips.append((i, rng.randint(1, N_PSG), rng.randint(1, N_DRV), fare, status,
                      t.strftime("%Y-%m-%d %H:%M:%S")))
        details.append((i, tier_id, zone_id, rating))

    # 3) Payment：completed 97% 支付 + 收费取消恰一条（D-06 v1.2 / A4 §三）
    payments, pay_id = [], 1
    for tr, td in zip(trips, details):
        _, _, _, fare, status, _ = tr
        if status == "completed" and rng.random() < P_COMPLETED_PAID:
            payments.append((pay_id, tr[0], fare, rng.choices(METHODS, weights=METHOD_W)[0]))
            pay_id += 1
        elif status == "canceled" and fare == CANCEL_FEE:
            payments.append((pay_id, tr[0], CANCEL_FEE, rng.choices(METHODS, weights=METHOD_W)[0]))
            pay_id += 1

    return passengers, vehicles, drivers, trips, details, payments


# ──────────────────────────────────────────────────────────────
# SQL 文件输出（多行 VALUES 批量插入；表序满足 FK 依赖）
# ──────────────────────────────────────────────────────────────
def _esc(v):
    # 所有字符串一律加引号：裸写 completed/cash 会被 MySQL 解析为列名
    # （真机导入踩坑：Unknown column 'completed' —— 2026-10-27 修复）
    if v is None:
        return "NULL"
    if isinstance(v, str):
        return "'" + v.replace("\\", "\\\\").replace("'", "\\'") + "'"
    if isinstance(v, float):
        return f"{v:.2f}"
    return str(v)


def write_sql(path, passengers, vehicles, drivers, trips, details, payments):
    def batch(table, cols, rows, size=500):
        out = []
        for k in range(0, len(rows), size):
            vals = ",\n".join("  (" + ",".join(_esc(v) for v in r) + ")" for r in rows[k:k + size])
            out.append(f"INSERT INTO {table} ({','.join(cols)}) VALUES\n{vals};\n")
        return out

    stmts = ["USE ride_hailing;\n"]
    stmts += batch("Passenger", ["psg_id", "name"], passengers)
    stmts += batch("Vehicle", ["vehicle_id", "plate"], vehicles)
    stmts += batch("Driver", ["driver_id", "name", "vehicle_id"], drivers)
    stmts += batch("Trip", ["trip_id", "psg_id", "driver_id", "fare", "status", "start_time"], trips)
    stmts += batch("Payment", ["pay_id", "trip_id", "amount", "method"], payments)
    stmts += batch("trip_detail", ["trip_id", "service_tier_id", "zone_id", "rating"], details)
    header = ("-- data_import.sql — 由 import_data.py 生成（seed=534），勿手改：\n"
              "--   重跑 python3 02_sql/import_data.py 即可逐字节复现（D-08③ 数据同源）\n"
              "--   导入前请先执行 02_sql/build.sql（建库 + 扩展表 + 维度 seed）\n\n")
    with open(path, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(stmts))
    return len(stmts)


# ──────────────────────────────────────────────────────────────
# 自验（A4 §四验收三条 + C3 扩展表不变量 + 分布摘要）
# ──────────────────────────────────────────────────────────────
def verify(passengers, vehicles, drivers, trips, details, payments):
    pay_by_trip = {}
    for p in payments:
        pay_by_trip.setdefault(p[1], []).append(p)

    bad_cancel, bad_rating, bad_detail = 0, 0, 0
    unpaid_completed = 0
    for tr, td in zip(trips, details):
        trip_id, _, _, fare, status, _ = tr
        pays = pay_by_trip.get(trip_id, [])
        # ① D-06：取消两类结果
        if status == "canceled":
            free = fare is None and not pays
            charged = fare == CANCEL_FEE and len(pays) == 1 and pays[0][2] == CANCEL_FEE
            if not (free or charged):
                bad_cancel += 1
        elif status == "completed" and not pays:
            unpaid_completed += 1
        # C3 不变量：恰一行扩展；rating 仅 completed 非空
        if td[0] != trip_id or td[3] is not None and status != "completed":
            bad_detail += 1
    # ② status 词表 ③ method 词表
    assert {t[4] for t in trips} <= {"completed", "canceled", "accepted", "en_route"}
    assert {p[3] for p in payments} <= set(METHODS)
    assert len({v[1] for v in vehicles}) == N_VEH            # plate 唯一
    assert {d[2] for d in drivers} == set(range(1, N_VEH + 1))  # Driver↔Vehicle 1:1
    assert len(details) == len(trips)
    assert bad_cancel == 0 and bad_detail == 0, (bad_cancel, bad_detail)

    n_cancel_charge = sum(1 for t in trips if t[4] == "canceled" and t[3] == CANCEL_FEE)
    comp_fares = [t[3] for t in trips if t[4] == "completed"]
    rated = [d[3] for d in details if d[3] is not None]
    peak = sum(1 for t in trips if 17 <= int(t[5][11:13]) <= 20)
    top3 = sum(1 for d in details if d[2] in (1, 2, 3))
    from collections import Counter
    method_c, star_c = Counter(p[3] for p in payments), Counter(rated)

    print("── 自验通过（验收三条 + C3 不变量 + 1:1/唯一约束）──")
    print(f"Passenger {len(passengers):>6} | Vehicle {len(vehicles):>3} | Driver {len(drivers):>3} "
          f"| Trip {len(trips):>6} | Payment {len(payments):>6} | trip_detail {len(details):>6}")
    print(f"status：completed {len(comp_fares)} / canceled {N_CANCELED}"
          f"（收费 {n_cancel_charge} + 免费 {N_CANCELED - n_cancel_charge}）"
          f" / accepted+en_route {N_ACCEPTED + N_EN_ROUTE}")
    print(f"D-06 取消规则违例 {bad_cancel}｜completed 未支付 {unpaid_completed}（Q2 反连接非空 ✓）")
    print(f"档次占比：" + " / ".join(f"{TIERS[k][0]} {v / 600:.1f}%" for k, v in
          sorted(Counter(d[1] for d in details).items())))
    print(f"区位 top3 占比 {top3 / 600:.1f}%（目标 35%）")
    print(f"评分覆盖率（completed）{len(rated) / N_COMPLETED * 100:.1f}%（目标 90%）｜"
          + " / ".join(f"{k}★ {star_c[k] / len(rated) * 100:.1f}%" for k in sorted(star_c, reverse=True)))
    print(f"completed 均费 ${sum(comp_fares) / len(comp_fares):.2f}（标定参照 $13.99）｜"
          f"min ${min(comp_fares):.2f} / max ${max(comp_fares):.2f}")
    print(f"晚高峰 17–20 时占比 {peak / 600:.1f}%（目标 ≈20%）")
    print(f"支付方式：" + " / ".join(f"{m} {method_c[m] / len(payments) * 100:.1f}%" for m in METHODS))


# ──────────────────────────────────────────────────────────────
# --load：直连 MySQL 导入并跑 SQL 级验收（依赖 pymysql，可选）
# ──────────────────────────────────────────────────────────────
def load_mysql(host, user, password, database, path):
    import pymysql
    import os
    password = password or os.environ.get("MYSQL_PWD", "cds534pass")  # 缺省=组内预研脚本值
    try:
        conn = pymysql.connect(host=host, user=user, password=password, database=database,
                               charset="utf8mb4", local_infile=False)
    except pymysql.err.OperationalError as e:
        if e.args and e.args[0] == 1045:
            sys.exit(f"MySQL 认证失败（{user}@{host}）：请用 --password 指定本机密码，"
                     f"或环境变量 MYSQL_PWD。导入前先跑 02_sql/build.sql。")
        raise
    cur = conn.cursor()
    buf = []
    for line in open(path, encoding="utf-8"):
        if line.lstrip().startswith("--"):
            continue
        buf.append(line)
        if line.rstrip().endswith(";"):
            stmt = "".join(buf)
            cur.execute(stmt)
            buf = []
    conn.commit()
    for label, sql in [
        ("各表行数（应为 3000/150/150/60000/51324/4/15/60000）",
         "SELECT 'Passenger',COUNT(*) FROM Passenger UNION ALL SELECT 'Vehicle',COUNT(*) FROM Vehicle "
         "UNION ALL SELECT 'Driver',COUNT(*) FROM Driver UNION ALL SELECT 'Trip',COUNT(*) FROM Trip "
         "UNION ALL SELECT 'Payment',COUNT(*) FROM Payment UNION ALL SELECT 'service_tier',COUNT(*) FROM service_tier "
         "UNION ALL SELECT 'pickup_zone',COUNT(*) FROM pickup_zone UNION ALL SELECT 'trip_detail',COUNT(*) FROM trip_detail"),
        ("验收①违反 D-06 的取消行（应为 0）",
         "SELECT COUNT(*) FROM Trip t LEFT JOIN Payment p ON p.trip_id=t.trip_id "
         "WHERE t.status='canceled' AND NOT ((t.fare IS NULL AND p.pay_id IS NULL) OR "
         "(t.fare=1.50 AND p.pay_id IS NOT NULL))"),
        ("验收② 非法 status 行（应为 0）",
         "SELECT COUNT(*) FROM Trip WHERE status NOT IN ('completed','canceled','accepted','en_route')"),
        ("验收③ 非法 method 行（应为 0）",
         "SELECT COUNT(*) FROM Payment WHERE method NOT IN ('balance','cash','card')"),
        ("C3 不变量：rating 非 completed 非空的行（应为 0）",
         "SELECT COUNT(*) FROM Trip t JOIN trip_detail d ON d.trip_id=t.trip_id "
         "WHERE d.rating IS NOT NULL AND t.status<>'completed'"),
        ("Q2 反连接：未支付完成的司机数（应 >0）",
         "SELECT COUNT(*) FROM (SELECT DISTINCT d.driver_id FROM Driver d JOIN Trip t ON t.driver_id=d.driver_id "
         "WHERE t.status='completed' AND NOT EXISTS (SELECT 1 FROM Payment p WHERE p.trip_id=t.trip_id)) x"),
    ]:
        cur.execute(sql)
        rows = cur.fetchall()
        print(f"[SQL] {label}: " + "; ".join(str(r) for r in rows[:9]))
    conn.close()


def main():
    ap = argparse.ArgumentParser(description="CDS534 Topic 5 样本数据生成器（C4）")
    ap.add_argument("--out", default=None, help="输出 SQL 文件路径（默认 02_sql/data_import.sql）")
    ap.add_argument("--load", action="store_true", help="生成后直连本机 MySQL 导入（需 pymysql）")
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--user", default="root")
    ap.add_argument("--password", default=None, help="缺省取 MYSQL_PWD 环境变量，再退组内预研默认值")
    ap.add_argument("--database", default="ride_hailing")
    args = ap.parse_args()

    out = args.out or (__file__.rsplit("/", 1)[0] + "/data_import.sql")
    data = generate()
    write_sql(out, *data)
    print(f"已生成 {out}（{sum(len(x) for x in data):,} 行数据）")
    verify(*data)
    if args.load:
        load_mysql(args.host, args.user, args.password, args.database, out)
        print("已导入 MySQL 并完成 SQL 级验收。")


if __name__ == "__main__":
    sys.exit(main())
