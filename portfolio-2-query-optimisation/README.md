# Portfolio 2 — Query Processing and Optimisation

## Overview

This module demonstrates analytical query design, execution plan inspection (`EXPLAIN (ANALYZE, BUFFERS)`), and index-driven query optimisation for **CareBridge Specialist Clinic, Abuja**.

## Files in this folder

| File | Purpose | 
| ----- | ----- | 
| `queries.sql` | Four operational and analytical queries covering patient medical history, departmental revenue, abnormal lab turnaround time, and pharmacy stock valuation | 
| `optimisation.sql` | Benchmarks execution plans before and after adding B-Tree composite and partial indexes | 
| `screenshots/` | Terminal outputs of the SQL queries and before/after `EXPLAIN ANALYZE` plans | 

## 1. Operational and Analytical Queries (`queries.sql`)

1. **Patient Medical History & Prescriptions (`JOIN` + `STRING_AGG`):** Joins `consultation`, `appointment`, `patient`, `doctor`, `department`, `prescription`, `prescription_item`, and `medication` to generate a consolidated clinical summary per visit.

2. **Departmental Revenue Breakdown (`FILTER` aggregation):** Computes total visits, completed visits, collected revenue (`Paid`), and outstanding bills (`Pending`) per clinic department.

3. **Abnormal Lab Result Turnaround Time:** Filters `lab_order` for abnormal completed tests and calculates lab processing time in minutes using `EXTRACT(EPOCH FROM (completed_at - requested_at)) / 60`.

4. **Pharmacy Dispensing & Inventory Valuation:** Aggregates total dispensed units and Naira value alongside current shelf stock.

## 2. Query Processing & Optimisation Analysis (`optimisation.sql`)

### Workload Tested

Clinicians frequently open a patient's file to view all past completed visits sorted from most recent to oldest:

```sql
SELECT appointment_id, doctor_id, scheduled_at, status, reason
FROM appointment
WHERE patient_id = 1
  AND status = 'Completed'
ORDER BY scheduled_at DESC;
```

### Why Baseline Setup Used Synthetic Rows

With only 10 rows in `appointment`, PostgreSQL's cost-based optimiser rightly chooses a `Seq Scan` because the entire table fits inside a single 8 KB heap page. To reflect realistic clinic volume, `optimisation.sql` temporarily seeds 5,000 historical appointments, updates planner statistics with `ANALYZE`, compares execution plans before and after indexing, and cleans up the synthetic rows afterward.

### Performance Comparison (Before vs. After Indexing)

| Metric | Before Indexing | After Indexing (`idx_appointment_patient_status`) | 
| ----- | ----- | ----- | 
| **Scan Operator** | `Seq Scan on appointment` | `Bitmap Index Scan on idx_appointment_patient_status` + `Bitmap Heap Scan` | 
| **Total Plan Cost** | `166.82..168.17` | `117.66..119.02` (~29.2% cost reduction) | 
| **Rows Removed by Filter** | `4,509` non-matching rows scanned and discarded | `0` rows discarded (exact index bitmap lookup) | 
| **Scan Actual Time** | `0.007..0.258 ms` | `0.043..0.148 ms` | 
| **Total Execution Time** | `0.346 ms` | `0.241 ms` (~30.3% faster) | 

### Indexing Strategy Justification

1. **Composite B-Tree Index (`idx_appointment_patient_status` on `(patient_id, status, scheduled_at DESC)`):**

   * Leading columns `(patient_id, status)` satisfy the equality predicates `WHERE patient_id = 1 AND status = 'Completed'`, allowing PostgreSQL to use a `Bitmap Index Scan` instead of scanning and discarding 4,509 unrelated rows.

2. **Partial Index (`idx_lab_order_abnormal_completed` on `(completed_at) WHERE status = 'Completed' AND is_abnormal = TRUE`):**

   * Most clinic lab tests return normal results. Indexing only abnormal completed orders keeps the index footprint small and avoids index maintenance overhead when normal results are inserted.

3. **Foreign Key & Lookup Index (`idx_consultation_icd10` on `(icd10_code)`):**

   * Accelerates epidemiological reporting by WHO ICD-10 disease code (e.g. `B54` for malaria, `I10` for hypertension).

## Reflection

Running `EXPLAIN (ANALYZE, BUFFERS)` highlighted how PostgreSQL's cost-based planner chooses between a `Seq Scan`, `Index Scan`, and `Bitmap Heap Scan`. Because Patient 1 accounted for 501 of the 5,010 rows (~10% of the table) spread across all 67 heap blocks, the planner chose a `Bitmap Index Scan` + `Bitmap Heap Scan` rather than random page-by-page index lookups, eliminating the 4,509 discarded filter rows and reducing total execution time from `0.346 ms` to `0.241 ms`.