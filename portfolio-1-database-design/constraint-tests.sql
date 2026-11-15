-- =====================================================================
-- Constraint tests — each statement below SHOULD FAIL.
-- Run: psql -U postgres -d clinic -f constraint-tests.sql
-- Screenshot the error messages as evidence that the constraints work.
-- =====================================================================

\echo '--- Test 1: Doctor double-booked in the same slot (UNIQUE uq_doctor_slot)'
INSERT INTO appointment (patient_id, doctor_id, scheduled_at, reason)
VALUES (2, 1, '2026-11-20 09:00', 'Should fail: Dr Okafor already booked');

\echo '--- Test 2: Appointment for a patient who does not exist (FOREIGN KEY)'
INSERT INTO appointment (patient_id, doctor_id, scheduled_at)
VALUES (999, 1, '2026-12-01 09:00');

\echo '--- Test 3: Invalid genotype (CHECK)'
INSERT INTO patient (hospital_number, first_name, last_name, date_of_birth, gender, genotype, phone)
VALUES ('CBC-2026-00099', 'Test', 'Patient', '2000-01-01', 'M', 'XY', '08000000000');

\echo '--- Test 4: Negative medication stock (CHECK)'
UPDATE medication SET stock_quantity = -5 WHERE medication_id = 1;

\echo '--- Test 5: Lab order marked Completed with no result (table CHECK)'
UPDATE lab_order SET status = 'Completed' WHERE lab_order_id = 5;

\echo '--- Test 6: Deleting a department that still has doctors (ON DELETE RESTRICT)'
DELETE FROM department WHERE department_id = 3;

\echo '--- Test 7: Duplicate MDCN licence number (UNIQUE)'
INSERT INTO doctor (first_name, last_name, specialisation, department_id, mdcn_number, email, phone)
VALUES ('Fake', 'Doctor', 'GP', 1, 'MDCN/R/41203', 'fake@carebridge.ng', '08000000001');
