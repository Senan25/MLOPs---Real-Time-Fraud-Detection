"""Generate realistic card transactions (with fraud labels) and append them to PostgreSQL.

Each run creates BATCH_SIZE transactions with timestamps spread over the last
WINDOW_MINUTES, so a CronJob running every WINDOW_MINUTES gives a continuous stream.

Env vars:
  DB_HOST, DB_PORT (5432), DB_NAME, DB_USER, DB_PASSWORD
  BATCH_SIZE (500), WINDOW_MINUTES (5), FRAUD_RATE (0.02), N_USERS (5000)
  DRY_RUN=1  -> print sample rows instead of writing to the database
"""
import os
import random
import uuid
from datetime import datetime, timedelta, timezone

BATCH_SIZE = int(os.getenv("BATCH_SIZE", "500"))
WINDOW_MINUTES = int(os.getenv("WINDOW_MINUTES", "5"))
FRAUD_RATE = float(os.getenv("FRAUD_RATE", "0.02"))
N_USERS = int(os.getenv("N_USERS", "5000"))
DRY_RUN = os.getenv("DRY_RUN") == "1"

COUNTRIES = ["AZ", "TR", "GE", "RU", "DE", "GB", "US", "AE"]
HOME_WEIGHTS = [70, 8, 5, 4, 4, 3, 4, 2]

# category: (amount multiplier, normal weight, fraud weight)
CATEGORIES = {
    "grocery":     (0.6, 30, 3),
    "restaurant":  (0.8, 20, 3),
    "fuel":        (1.0, 10, 2),
    "transport":   (0.4, 12, 1),
    "pharmacy":    (0.7, 6, 1),
    "clothing":    (1.5, 10, 10),
    "electronics": (4.0, 4, 25),
    "travel":      (6.0, 3, 15),
    "gift_cards":  (3.0, 1.5, 22),
    "crypto":      (5.0, 0.5, 18),
}
CAT_NAMES = list(CATEGORIES)
NORMAL_W = [CATEGORIES[c][1] for c in CAT_NAMES]
FRAUD_W = [CATEGORIES[c][2] for c in CAT_NAMES]


def user_profile(user_id):
    """Stable profile per user: same user_id always gets the same home country and spending level."""
    r = random.Random(user_id)
    return {
        "home": r.choices(COUNTRIES, weights=HOME_WEIGHTS)[0],
        "avg": r.lognormvariate(3.4, 0.5),  # typical spend, median ~30
    }


def make_tx(now):
    user_id = random.randint(1, N_USERS)
    p = user_profile(user_id)
    ts = now - timedelta(seconds=random.uniform(0, WINDOW_MINUTES * 60))

    # fraud is ~3x more likely between 00:00 and 05:00
    rate = FRAUD_RATE * (3 if ts.hour < 5 else 1)
    fraud = random.random() < rate
    subtle = fraud and random.random() < 0.15  # hard cases that look almost normal

    if fraud and not subtle:
        cat = random.choices(CAT_NAMES, weights=FRAUD_W)[0]
        amount = p["avg"] * CATEGORIES[cat][0] * random.uniform(2, 8)
        abroad = random.random() < 0.7
        country = random.choice([c for c in COUNTRIES if c != p["home"]]) if abroad else p["home"]
        channel = random.choices(["online", "pos", "atm"], weights=[75, 15, 10])[0]
        card_present = channel != "online" and random.random() < 0.3
        new_device = random.random() < 0.8
        tx_1h = random.randint(3, 12)
    else:
        cat = random.choices(CAT_NAMES, weights=NORMAL_W)[0]
        amount = p["avg"] * CATEGORIES[cat][0] * random.lognormvariate(0, 0.35)
        country = p["home"] if random.random() < 0.95 else random.choice(COUNTRIES)
        channel = random.choices(["pos", "online", "atm"], weights=[55, 40, 5])[0]
        card_present = channel != "online"
        new_device = random.random() < 0.03
        tx_1h = random.choices([0, 1, 2, 3], weights=[60, 28, 9, 3])[0]
        if subtle:
            channel, card_present, new_device = "online", False, True

    distance = random.uniform(500, 8000) if country != p["home"] else random.uniform(0, 30)
    if fraud and not subtle and country == p["home"]:
        distance = random.uniform(50, 500)

    return (
        str(uuid.uuid4()), user_id, ts, round(amount, 2), cat, channel, country,
        p["home"], card_present, new_device, tx_1h, round(distance, 1),
        round(p["avg"], 2), fraud,
    )


COLUMNS = (
    "transaction_id", "user_id", "event_time", "amount", "merchant_category", "channel",
    "country", "home_country", "card_present", "is_new_device", "tx_count_1h",
    "distance_from_home_km", "user_avg_amount", "is_fraud",
)

DDL = """
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id        UUID PRIMARY KEY,
    user_id               INT NOT NULL,
    event_time            TIMESTAMPTZ NOT NULL,
    amount                NUMERIC(12,2) NOT NULL,
    merchant_category     TEXT,
    channel               TEXT,
    country               CHAR(2),
    home_country          CHAR(2),
    card_present          BOOLEAN,
    is_new_device         BOOLEAN,
    tx_count_1h           INT,
    distance_from_home_km NUMERIC(8,1),
    user_avg_amount       NUMERIC(12,2),
    is_fraud              BOOLEAN NOT NULL,
    created_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_transactions_event_time ON transactions (event_time);
"""


def main():
    now = datetime.now(timezone.utc)
    rows = [make_tx(now) for _ in range(BATCH_SIZE)]
    rows.sort(key=lambda r: r[2])

    if DRY_RUN:
        print(",".join(COLUMNS))
        for r in rows[:15]:
            print(",".join(str(v) for v in r))
        frauds = sum(r[-1] for r in rows)
        print(f"\n{len(rows)} rows generated, {frauds} fraud ({frauds / len(rows):.1%})")
        return

    import psycopg2
    from psycopg2.extras import execute_values

    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        sslmode="require",
        connect_timeout=15,
    )
    with conn, conn.cursor() as cur:
        cur.execute(DDL)
        execute_values(
            cur,
            f"INSERT INTO transactions ({', '.join(COLUMNS)}) VALUES %s ON CONFLICT DO NOTHING",
            rows,
        )
    conn.close()
    print(f"Inserted {len(rows)} rows ({sum(r[-1] for r in rows)} fraud)")


if __name__ == "__main__":
    main()