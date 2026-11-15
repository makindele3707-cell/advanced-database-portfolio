-- =====================================================================
-- CareBridge Specialist Clinic — Isolation Levels & Concurrency Control
-- MIT 8103 Advanced Database Systems — Portfolio 3
-- Run: psql -U postgres -d clinic -f concurrency-demo.sql
-- =====================================================================

\echo '================================================================='
\echo 'DEMO 1: Snapshot Isolation (REPEATABLE READ) Preventing Non-Repeatable Reads'
\echo '================================================================='
-- When the Finance Officer runs a financial audit report across multiple queries,
-- REPEATABLE READ guarantees a consistent snapshot even if other transactions
-- commit new payments while the report is running.

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT COALESCE(SUM(amount), 0) AS total_paid_snapshot_1
FROM payment
WHERE status = 'Paid';

-- Verify active transaction isolation level
SHOW transaction_isolation;

COMMIT;


\echo '================================================================='
\echo 'DEMO 2: Pessimistic Row-Level Locking (SELECT ... FOR UPDATE)'
\echo '================================================================='
-- Prevents the Lost Update concurrency anomaly when two pharmacists
-- simultaneously check and deduct stock for Salbutamol Inhaler (medication_id = 4).

BEGIN;

\echo '--- Acquiring exclusive row lock (FOR UPDATE) on Salbutamol (medication_id = 4) ---'
SELECT medication_id, name, stock_quantity
FROM medication
WHERE medication_id = 4
FOR UPDATE;

\echo '--- Inspecting active row-level and table-level locks in pg_locks ---'
SELECT l.locktype,
       c.relname AS relation,
       l.mode,
       l.granted
FROM pg_locks l
JOIN pg_class c ON l.relation = c.oid
WHERE c.relname = 'medication';

-- Safely deduct 2 inhalers while holding the row lock
UPDATE medication
SET stock_quantity = stock_quantity - 2
WHERE medication_id = 4;

SELECT medication_id, name, stock_quantity AS updated_stock
FROM medication
WHERE medication_id = 4;

-- Roll back demo change to preserve baseline stock (40)
ROLLBACK;