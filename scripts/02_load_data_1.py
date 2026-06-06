"""
Загрузка Brazilian E-Commerce в PostgreSQL.
Использует copy_expert (клиентский COPY) — работает без прав администратора.
"""

import psycopg2
import os

# === НАСТРОЙКИ ===
DB_CONFIG = {
    "host":     "localhost",
    "port":     5432,
    "dbname":   "ecommerce",
    "user":     "postgres",
    "password": "dfgcvb79",  # вставь свой пароль если есть
}

CSV_DIR = r"C:\Users\Asus\Downloads\archive"

TABLES = [
    ("product_category_translation", "product_category_name_translation.csv"),
    ("customers",      "olist_customers_dataset.csv"),
    ("products",       "olist_products_dataset.csv"),
    ("sellers",        "olist_sellers_dataset.csv"),
    ("orders",         "olist_orders_dataset.csv"),
    ("order_items",    "olist_order_items_dataset.csv"),
    ("order_payments", "olist_order_payments_dataset.csv"),
    ("order_reviews",  "olist_order_reviews_dataset.csv"),
]

conn = psycopg2.connect(**DB_CONFIG)
conn.autocommit = True
cur = conn.cursor()

for table, filename in TABLES:
    filepath = os.path.join(CSV_DIR, filename)
    if not os.path.exists(filepath):
        print(f"[SKIP] файл не найден: {filepath}")
        continue

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            cur.copy_expert(
                f"COPY {table} FROM STDIN DELIMITER ',' CSV HEADER NULL ''",
                f
            )
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        count = cur.fetchone()[0]
        print(f"[OK] {table}: {count:,} строк")
    except Exception as e:
        print(f"[ERROR] {table}: {e}")

cur.close()
conn.close()
print("\nГотово!")
