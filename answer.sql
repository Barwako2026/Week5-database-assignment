-- ============================================
-- STEP 1: Generate a Big Table
-- ============================================
CREATE TABLE orders (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id INT,
  amount NUMERIC(10,2),
  status TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO orders (customer_id, amount, status, created_at)
SELECT
  (random()*50000)::int,
  (random()*500)::numeric(10,2),
  (ARRAY['pending','shipped','delivered'])[ceil(random()*3)],
  now() - (random()*365)::int * interval '1 day'
FROM generate_series(1, 2000000);

ANALYZE orders;

-- ============================================
-- STEP 2: Measure the Slow Query (BEFORE index)
-- ============================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, SUM(amount)
FROM orders
WHERE status = 'pending'
  AND created_at > now() - interval '30 days'
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 10;

-- >>> RECORD HERE: Execution Time + whether it used Seq Scan or Index Scan.

-- ============================================
-- STEP 3: Add a Targeted Index and Re-Measure
-- ============================================
CREATE INDEX idx_pending_recent
ON orders (created_at DESC, customer_id)
WHERE status = 'pending';

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, SUM(amount)
FROM orders
WHERE status = 'pending'
  AND created_at > now() - interval '30 days'
GROUP BY customer_id
ORDER BY SUM(amount) DESC
LIMIT 10;

-- >>> RECORD HERE: new Execution Time + confirm Index/Bitmap Scan on idx_pending_recent.
-- >>> Compare before vs after.

-- ============================================
-- STEP 4: Observe Isolation Levels (needs TWO psql sessions)
-- ============================================

-- --- Session 1 ---
BEGIN;
-- Alternative: BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT amount FROM orders WHERE id = 1;
-- >>> RECORD HERE: value returned. Leave transaction open, switch to Session 2.

-- --- Session 2 ---
UPDATE orders SET amount = 9999 WHERE id = 1;
COMMIT;

-- --- Back to Session 1 ---
SELECT amount FROM orders WHERE id = 1;
-- >>> RECORD HERE: value returned this time.
-- >>> READ COMMITTED expects 9999; REPEATABLE READ expects the old value.
COMMIT;

-- ============================================
-- STEP 5: Set Up PgBouncer (run in Linux shell, not psql)
-- ============================================
-- sudo apt install -y pgbouncer

-- Edit /etc/pgbouncer/pgbouncer.ini:
-- [databases]
-- bootcamp = host=127.0.0.1 port=5432 dbname=bootcamp
--
-- [pgbouncer]
-- pool_mode = transaction
-- max_client_conn = 1000
-- default_pool_size = 20
-- listen_port = 6432

-- sudo systemctl restart pgbouncer
-- psql -h 127.0.0.1 -p 6432 -U postgres bootcamp

-- >>> RECORD HERE: confirm successful connection through port 6432.
