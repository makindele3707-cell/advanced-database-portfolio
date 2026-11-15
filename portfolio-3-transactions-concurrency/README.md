# Portfolio 3 — Transactions and Concurrency Control

## Overview

This module demonstrates ACID transaction management (`BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`), transaction isolation levels (`REPEATABLE READ`), and pessimistic concurrency control (`SELECT ... FOR UPDATE`) for **CareBridge Specialist Clinic, Abuja**.

## Files in this folder

| File | Purpose |
|---|---|
| `transactions.sql` | Demonstrates atomic multi-table `COMMIT`, constraint-triggered `ROLLBACK`, and partial rollback with `SAVEPOINT` |
| `concurrency-demo.sql` | Demonstrates `REPEATABLE READ` snapshot isolation and `SELECT ... FOR UPDATE` row-level locking with `pg_locks` inspection |
| `screenshots/` | Terminal output evidence of the transaction and concurrency executions |

## 1. ACID Transaction Scenarios (`transactions.sql`)

### Scenario 1: Atomic Prescription Dispensing & Billing (`COMMIT`)
When a patient collects medication at the CareBridge pharmacy and pays via POS, three tables must be updated as a single atomic unit:
1. Deduct 10 tablets of *Glyceryl Trinitrate* (`medication_id = 8`) from `medication`.
2. Mark `prescription_id = 4` as `is_dispensed = TRUE` in `prescription`.
3. Update `payment_id = 4` from `Pending` to `Paid` with POS reference `POS-9904412`.

Wrapping all three statements in `BEGIN ... COMMIT` guarantees **Atomicity** and **Consistency**: either the clinic records both the stock deduction and the settled payment, or neither takes effect.

### Scenario 2: Failed Dispensing Rolled Back on Stock Shortage (`ROLLBACK`)
A pharmacist attempts to record a card payment of 125,000 NGN and dispense 50 *Salbutamol* inhalers (`medication_id = 4`), when only 40 exist in stock:
- The `UPDATE medication` statement violates the `CHECK (stock_quantity >= 0)` constraint.
- PostgreSQL immediately places the transaction into an aborted state, and `ROLLBACK` discards the preceding `INSERT INTO payment` (`POS-FAIL-999`), leaving `stock_quantity = 40` and preventing orphan payment records.

### Scenario 3: Partial Rollback Using `SAVEPOINT`
During Consultation #6, a doctor requests a *Full Blood Count* (`test_id = 2`), sets `SAVEPOINT after_fbc_order`, and accidentally orders an *ECG* (`test_id = 6`). Issuing `ROLLBACK TO SAVEPOINT after_fbc_order` undoes the mistaken ECG order while preserving the Full Blood Count order when the transaction commits.

## 2. Concurrency Issues and Control Mechanisms (`concurrency-demo.sql`)

### Concurrency Anomaly 1: Lost Update on Pharmacy Inventory
- **Problem:** Suppose only 1 *Salbutamol* inhaler remains (`stock_quantity = 1`). Pharmacist A and Pharmacist B both read `stock_quantity = 1` at the same time. Without locking, both sessions compute `1 - 1 = 0` or attempt to dispense the same unit concurrently.
- **Control Mechanism (`SELECT ... FOR UPDATE`):** Using pessimistic row-level locking (`SELECT ... FROM medication WHERE medication_id = 4 FOR UPDATE`) acquires an exclusive row lock (`RowShareLock` on the relation and tuple lock on the row, verified via `pg_locks`). A second concurrent transaction attempting to update or `FOR UPDATE` lock the same medication row is forced to wait until the first transaction commits or rolls back.

### Concurrency Anomaly 2: Non-Repeatable Reads During Financial Audits
- **Problem:** Under PostgreSQL's default `READ COMMITTED` isolation level, if a billing officer runs a multi-query reconciliation report while the front desk commits new payments, two `SUM(amount)` queries inside the same transaction can return different totals (a **non-repeatable read** / **phantom read**).
- **Control Mechanism (`BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ`):** Using PostgreSQL's Multiversion Concurrency Control (MVCC), `REPEATABLE READ` freezes a consistent snapshot as of the first query in the transaction, ensuring all financial calculations within the audit see the exact same committed dataset without blocking front-desk writes.

### Concurrency Anomaly 3: Doctor Double-Booking Race Condition
- **Problem:** Two receptionists simultaneously check if Dr Okafor (`doctor_id = 1`) is free at `2026-11-20 09:00` and both attempt to insert an appointment.
- **Control Mechanism:** Enforced at the storage engine level via the composite B-Tree unique index `uq_doctor_slot UNIQUE (doctor_id, scheduled_at)`. Even under concurrent inserts, PostgreSQL's B-Tree index locking blocks the second transaction until the first commits, and then rejects the duplicate slot with a unique violation error.

## Reflection

Implementing these scenarios showed how database integrity relies on combining declarative schema constraints with explicit transaction boundaries. While `CHECK (stock_quantity >= 0)` prevents negative inventory, explicit transactions (`BEGIN ... COMMIT/ROLLBACK`) ensure that a stock error also undoes the associated billing row, and `SELECT ... FOR UPDATE` prevents concurrent pharmacy sessions from reading stale inventory counts before updating.