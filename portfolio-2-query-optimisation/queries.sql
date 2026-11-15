-- =====================================================================
-- CareBridge Specialist Clinic — Operational & Analytical Queries
-- MIT 8103 Advanced Database Systems — Portfolio 2
-- Run: psql -U postgres -d clinic -f queries.sql
-- =====================================================================

\echo '=== Query 1: Full Patient Medical History & Prescriptions ==='
SELECT p.hospital_number,
       p.first_name || ' ' || p.last_name AS patient_name,
       d.first_name || ' ' || d.last_name AS doctor_name,
       dept.name AS department,
       c.diagnosis,
       c.icd10_code,
       STRING_AGG(m.name || ' (' || pi.dosage || ', ' || pi.frequency || ')', '; ') AS prescribed_drugs
FROM consultation c
JOIN appointment a          ON c.appointment_id = a.appointment_id
JOIN patient p              ON a.patient_id = p.patient_id
JOIN doctor d               ON a.doctor_id = d.doctor_id
JOIN department dept        ON d.department_id = dept.department_id
LEFT JOIN prescription pr   ON c.consultation_id = pr.consultation_id
LEFT JOIN prescription_item pi ON pr.prescription_id = pi.prescription_id
LEFT JOIN medication m      ON pi.medication_id = m.medication_id
GROUP BY p.hospital_number, patient_name, doctor_name, dept.name, c.diagnosis, c.icd10_code, a.scheduled_at
ORDER BY a.scheduled_at;

\echo '=== Query 2: Department Revenue & Appointment Completion Breakdown ==='
SELECT dept.name AS department,
       COUNT(DISTINCT a.appointment_id) AS total_appointments,
       COUNT(DISTINCT a.appointment_id) FILTER (WHERE a.status = 'Completed') AS completed_visits,
       COALESCE(SUM(pay.amount) FILTER (WHERE pay.status = 'Paid'), 0.00) AS collected_revenue_ngn,
       COALESCE(SUM(pay.amount) FILTER (WHERE pay.status = 'Pending'), 0.00) AS pending_revenue_ngn
FROM department dept
LEFT JOIN doctor d      ON dept.department_id = d.department_id
LEFT JOIN appointment a ON d.doctor_id = a.doctor_id
LEFT JOIN payment pay   ON a.appointment_id = pay.appointment_id
GROUP BY dept.department_id, dept.name
ORDER BY collected_revenue_ngn DESC;

\echo '=== Query 3: Abnormal Lab Results with Turnaround Time (Minutes) ==='
SELECT p.hospital_number,
       p.first_name || ' ' || p.last_name AS patient_name,
       lt.test_name,
       lo.result_value,
       lt.reference_range,
       ROUND(EXTRACT(EPOCH FROM (lo.completed_at - lo.requested_at)) / 60, 1) AS turnaround_mins
FROM lab_order lo
JOIN lab_test lt     ON lo.test_id = lt.test_id
JOIN consultation c  ON lo.consultation_id = c.consultation_id
JOIN appointment a   ON c.appointment_id = a.appointment_id
JOIN patient p       ON a.patient_id = p.patient_id
WHERE lo.status = 'Completed'
  AND lo.is_abnormal = TRUE
ORDER BY lo.completed_at;

\echo '=== Query 4: Pharmacy Dispensing Value & Remaining Inventory ==='
SELECT m.name AS medication,
       m.form,
       m.unit_price,
       COALESCE(SUM(pi.quantity) FILTER (WHERE pr.is_dispensed = TRUE), 0) AS units_dispensed,
       COALESCE(SUM(pi.quantity * m.unit_price) FILTER (WHERE pr.is_dispensed = TRUE), 0.00) AS dispensed_value_ngn,
       m.stock_quantity AS remaining_stock
FROM medication m
LEFT JOIN prescription_item pi ON m.medication_id = pi.medication_id
LEFT JOIN prescription pr      ON pi.prescription_id = pr.prescription_id
GROUP BY m.medication_id, m.name, m.form, m.unit_price, m.stock_quantity
ORDER BY dispensed_value_ngn DESC;