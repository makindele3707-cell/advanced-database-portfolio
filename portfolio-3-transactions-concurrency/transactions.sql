-- =====================================================================
-- CareBridge Specialist Clinic — ACID Transactions (Commit, Rollback, Savepoint)
-- MIT 8103 Advanced Database Systems — Portfolio 3
-- Run: psql -U postgres -d clinic -f transactions.sql
-- =====================================================================

\echo '================================================================='
\echo 'SCENARIO 1: Successful Atomic Prescription Dispensing & Billing (COMMIT)'
\echo '================================================================='
-- Prescription 4 (for Appointment 4 / Consultation 4, Patient Yusuf Danjuma)
-- prescribes 10 tablets of Glyceryl Trinitrate (medication_id = 8, stock = 200)
-- and has a Pending payment of 25,800 NGN (payment_id = 4).

\echo '--- Before Transaction: Check stock, prescription status, and payment ---'
SELECT medication_id, name, stock_quantity FROM medication WHERE medication_id = 8;
SELECT prescription_id, is_dispensed FROM prescription WHERE prescription_id = 4;
SELECT payment_id, appointment_id, amount, status, reference FROM payment WHERE payment_id = 4;

BEGIN;

-- Step 1: Deduct 10 tablets of Glyceryl Trinitrate from pharmacy stock
UPDATE medication
SET stock_quantity = stock_quantity - 10
WHERE medication_id = 8;

-- Step 2: Mark Prescription #4 as dispensed
UPDATE prescription
SET is_dispensed = TRUE
WHERE prescription_id = 4;

-- Step 3: Settle the pending POS card payment for Appointment #4
UPDATE payment
SET status = 'Paid',
    reference = 'POS-9904412',
    paid_at = NOW()
WHERE payment_id = 4;

COMMIT;

\echo '--- After COMMIT: All 3 updates persisted atomically ---'
SELECT medication_id, name, stock_quantity FROM medication WHERE medication_id = 8;
SELECT prescription_id, is_dispensed FROM prescription WHERE prescription_id = 4;
SELECT payment_id, appointment_id, amount, status, reference FROM payment WHERE payment_id = 4;


\echo '================================================================='
\echo 'SCENARIO 2: Failed Dispensing Rolled Back on Stock Shortage (ROLLBACK)'
\echo '================================================================='
-- Attempt to dispense 50 units of Salbutamol Inhaler (medication_id = 4),
-- which only has 40 units in stock. The CHECK (stock_quantity >= 0) constraint
-- triggers an error, aborting the transaction so no partial changes are saved.

BEGIN;

-- Step 1: Insert a new payment attempt
INSERT INTO payment (appointment_id, amount, method, status, reference, paid_at)
VALUES (3, 125000.00, 'Card', 'Paid', 'POS-FAIL-999', NOW());

-- Step 2: Attempt to deduct 50 inhalers when only 40 exist (violates CHECK constraint)
UPDATE medication
SET stock_quantity = stock_quantity - 50
WHERE medication_id = 4;

-- Step 3: Roll back the aborted transaction block
ROLLBACK;

\echo '--- After ROLLBACK: Salbutamol stock is still 40 and payment POS-FAIL-999 was discarded ---'
SELECT medication_id, name, stock_quantity FROM medication WHERE medication_id = 4;
SELECT COUNT(*) AS bogus_payment_count FROM payment WHERE reference = 'POS-FAIL-999';


\echo '================================================================='
\echo 'SCENARIO 3: Partial Rollback Using SAVEPOINT during Consultation'
\echo '================================================================='
-- Doctor records two lab orders for Consultation 6, realises the second test
-- (ECG) was ordered by mistake, rolls back to the savepoint, and commits the first.

BEGIN;

INSERT INTO lab_order (consultation_id, test_id, status)
VALUES (6, 2, 'Requested'); -- Full Blood Count (keep)

SAVEPOINT after_fbc_order;

INSERT INTO lab_order (consultation_id, test_id, status)
VALUES (6, 6, 'Requested'); -- ECG ordered by mistake (undo)

ROLLBACK TO SAVEPOINT after_fbc_order;

COMMIT;

\echo '--- After SAVEPOINT Rollback & COMMIT: Only Full Blood Count (test_id=2) was added ---'
SELECT lab_order_id, consultation_id, test_id, status
FROM lab_order
WHERE consultation_id = 6
ORDER BY lab_order_id;

-- Restore baseline state so script is idempotent
DELETE FROM lab_order WHERE consultation_id = 6 AND test_id = 2;
UPDATE medication SET stock_quantity = 200 WHERE medication_id = 8;
UPDATE prescription SET is_dispensed = FALSE WHERE prescription_id = 4;
UPDATE payment SET status = 'Pending', reference = NULL, paid_at = NULL WHERE payment_id = 4;