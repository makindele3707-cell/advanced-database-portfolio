-- =====================================================================
-- CareBridge Specialist Clinic — Query Processing & Index Optimisation
-- MIT 8103 Advanced Database Systems — Portfolio 2
-- Run: psql -U postgres -d clinic -f optimisation.sql
-- =====================================================================

-- 1. Drop custom indexes if re-running
DROP INDEX IF EXISTS idx_appointment_patient_status;
DROP INDEX IF EXISTS idx_lab_order_abnormal_completed;
DROP INDEX IF EXISTS idx_consultation_icd10;

-- 2. Seed synthetic historical appointments (5,000 rows) so the PostgreSQL
--    cost-based optimiser has realistic table statistics to evaluate.
\echo '--- Seeding 5,000 synthetic historical appointments for realistic benchmark ---'
INSERT INTO appointment (patient_id, doctor_id, scheduled_at, reason, status)
SELECT
    ((g % 8) + 1),
    ((g % 6) + 1),
    TIMESTAMP '2024-01-01 08:00:00' + (g || ' hours')::interval,
    'Routine outpatient follow-up #' || g,
    CASE
        WHEN g % 10 = 0 THEN 'Cancelled'
        WHEN g % 15 = 0 THEN 'No-Show'
        ELSE 'Completed'
    END
FROM generate_series(1, 5000) AS g
ON CONFLICT (doctor_id, scheduled_at) DO NOTHING;

ANALYZE appointment;
ANALYZE lab_order;
ANALYZE consultation;

\echo '================================================================='
\echo 'BEFORE INDEXING: Execution Plan (Patient Appointment Lookup)'
\echo '================================================================='
EXPLAIN (ANALYZE, BUFFERS)
SELECT appointment_id, doctor_id, scheduled_at, status, reason
FROM appointment
WHERE patient_id = 1
  AND status = 'Completed'
ORDER BY scheduled_at DESC;

\echo '--- Creating Composite & Partial B-Tree Indexes ---'
CREATE INDEX idx_appointment_patient_status
    ON appointment (patient_id, status, scheduled_at DESC);

CREATE INDEX idx_lab_order_abnormal_completed
    ON lab_order (completed_at)
    WHERE status = 'Completed' AND is_abnormal = TRUE;

CREATE INDEX idx_consultation_icd10
    ON consultation (icd10_code);

ANALYZE appointment;
ANALYZE lab_order;
ANALYZE consultation;

\echo '================================================================='
\echo 'AFTER INDEXING: Execution Plan (Patient Appointment Lookup)'
\echo '================================================================='
EXPLAIN (ANALYZE, BUFFERS)
SELECT appointment_id, doctor_id, scheduled_at, status, reason
FROM appointment
WHERE patient_id = 1
  AND status = 'Completed'
ORDER BY scheduled_at DESC;

-- Clean up the synthetic benchmark rows so sample data returns to baseline
DELETE FROM appointment WHERE reason LIKE 'Routine outpatient follow-up #%';
ANALYZE appointment;