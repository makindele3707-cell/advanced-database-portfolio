-- =====================================================================
-- CareBridge Specialist Clinic — Sample Data
-- Run after schema.sql:  psql -U postgres -d clinic -f sample-data.sql
-- All people and records below are fictional.
-- =====================================================================

INSERT INTO department (name, floor, phone_extension) VALUES
('General Medicine', 1, '101'),
('Paediatrics',      1, '102'),
('Cardiology',       2, '201'),
('Obstetrics & Gynaecology', 2, '202'),
('Laboratory',       0, '001');

INSERT INTO doctor (first_name, last_name, specialisation, department_id, mdcn_number, email, phone, hire_date) VALUES
('Adaeze',   'Okafor',   'Family Physician',        1, 'MDCN/R/41203', 'a.okafor@carebridge.ng',   '08031234501', '2019-03-01'),
('Ibrahim',  'Musa',     'Internal Medicine',       1, 'MDCN/R/38877', 'i.musa@carebridge.ng',     '08031234502', '2020-07-15'),
('Funmilayo','Adeyemi',  'Paediatrician',           2, 'MDCN/R/44510', 'f.adeyemi@carebridge.ng',  '08031234503', '2021-01-10'),
('Chinedu',  'Eze',      'Cardiologist',            3, 'MDCN/R/35092', 'c.eze@carebridge.ng',      '08031234504', '2018-11-20'),
('Hauwa',    'Bello',    'Obstetrician',            4, 'MDCN/R/46731', 'h.bello@carebridge.ng',    '08031234505', '2022-05-02'),
('Tunde',    'Bakare',   'Pathologist',             5, 'MDCN/R/39954', 't.bakare@carebridge.ng',   '08031234506', '2020-02-17');

INSERT INTO patient (hospital_number, first_name, last_name, date_of_birth, gender, blood_group, genotype, phone, email, address, nhis_number) VALUES
('CBC-2026-00001','Emeka',   'Nwosu',    '1985-04-12','M','O+','AA','08051110001','emeka.nwosu@mail.com',  '12 Aminu Kano Cres, Wuse II, Abuja', 'NHIS-7781201'),
('CBC-2026-00002','Aisha',   'Abdullahi','1992-09-30','F','A+','AS','08051110002','aisha.a@mail.com',      '4 Gana St, Maitama, Abuja',         NULL),
('CBC-2026-00003','Tobi',    'Ogunleye', '2019-06-18','M','B+','AA','08051110003', NULL,                   '9 Ahmadu Bello Way, Garki, Abuja',   'NHIS-7781202'),
('CBC-2026-00004','Ngozi',   'Obi',      '1978-01-05','F','O-','AS','08051110004','ngozi.obi@mail.com',    '21 Adetokunbo Ademola, Wuse II',     NULL),
('CBC-2026-00005','Yusuf',   'Danjuma',  '1960-11-23','M','AB+','AA','08051110005', NULL,                  '3 Kubwa Expressway, Kubwa, Abuja',   'NHIS-7781203'),
('CBC-2026-00006','Blessing','Etim',     '1996-03-14','F','O+','AA','08051110006','blessing.etim@mail.com','15 Lake Chad Cres, Maitama',         NULL),
('CBC-2026-00007','Zainab',  'Lawal',    '2021-12-02','F','A-','AS','08051110007', NULL,                   '7 Gwarinpa 1st Ave, Abuja',          'NHIS-7781204'),
('CBC-2026-00008','Olumide', 'Fashola',  '1955-08-09','M','B-','AA','08051110008','o.fashola@mail.com',    '40 Jabi Lake Rd, Jabi, Abuja',       NULL);

INSERT INTO patient_allergy (patient_id, allergen, severity) VALUES
(1, 'Penicillin', 'Severe'),
(1, 'Peanuts',    'Mild'),
(4, 'Sulfonamides','Moderate'),
(8, 'Aspirin',    'Moderate');

INSERT INTO appointment (patient_id, doctor_id, scheduled_at, reason, status) VALUES
(1, 1, '2026-10-05 09:00', 'Fever and headache',             'Completed'),
(2, 5, '2026-10-05 10:00', 'Antenatal check-up',             'Completed'),
(3, 3, '2026-10-06 09:30', 'Persistent cough',               'Completed'),
(5, 4, '2026-10-06 11:00', 'Chest pain on exertion',         'Completed'),
(4, 2, '2026-10-07 14:00', 'Routine diabetes review',        'Completed'),
(6, 1, '2026-10-08 09:00', 'Abdominal pain',                 'Cancelled'),
(7, 3, '2026-10-09 10:30', 'Vaccination follow-up',          'No-Show'),
(8, 4, '2026-10-12 11:00', 'Hypertension review',            'Completed'),
(1, 1, '2026-11-20 09:00', 'Malaria follow-up',              'Scheduled'),
(6, 2, '2026-11-20 10:00', 'Rescheduled abdominal pain',     'Scheduled');

INSERT INTO consultation (appointment_id, symptoms, diagnosis, icd10_code, notes, weight_kg, bp_systolic, bp_diastolic, temperature_c) VALUES
(1, 'High fever, headache, body aches for 3 days', 'Uncomplicated malaria',       'B54',  'RDT positive. Start ACT.',              78.5, 120, 80, 38.9),
(2, 'No complaints, 24 weeks gestation',           'Normal pregnancy supervision','Z34',  'Fundal height normal.',                 68.0, 110, 70, 36.7),
(3, 'Dry cough for 2 weeks, mild wheeze',          'Acute bronchitis',            'J20',  'No fever. Review in 1 week.',           18.2, NULL, NULL, 37.1),
(4, 'Chest tightness when climbing stairs',        'Stable angina',               'I20.8','ECG ordered. Refer for stress test.',   91.0, 150, 95, 36.8),
(5, 'Increased thirst, fatigue',                   'Type 2 diabetes mellitus',    'E11',  'HbA1c requested. Adjust metformin.',    84.3, 135, 85, 36.6),
(8, 'Occasional dizziness',                        'Essential hypertension',      'I10',  'Continue amlodipine. Check lipids.',    80.1, 160, 100, 36.5);

INSERT INTO medication (name, form, strength, unit_price, stock_quantity) VALUES
('Artemether/Lumefantrine', 'Tablet',  '20/120 mg', 150.00, 600),
('Paracetamol',             'Tablet',  '500 mg',     20.00, 2000),
('Amoxicillin',             'Capsule', '500 mg',     60.00, 800),
('Salbutamol',              'Inhaler', '100 mcg',  2500.00, 40),
('Metformin',               'Tablet',  '500 mg',     35.00, 1200),
('Amlodipine',              'Tablet',  '5 mg',       45.00, 900),
('Ferrous Sulphate',        'Tablet',  '200 mg',     15.00, 1500),
('Glyceryl Trinitrate',     'Tablet',  '0.5 mg',     80.00, 200);

INSERT INTO prescription (consultation_id, is_dispensed) VALUES
(1, TRUE), (2, TRUE), (3, TRUE), (4, FALSE), (5, TRUE), (6, TRUE);

INSERT INTO prescription_item (prescription_id, medication_id, dosage, frequency, duration_days, quantity) VALUES
(1, 1, '4 tablets', 'twice daily',      3, 24),
(1, 2, '2 tablets', 'three times daily',3, 18),
(2, 7, '1 tablet',  'once daily',      30, 30),
(3, 4, '2 puffs',   'as needed',        7,  1),
(4, 8, '1 tablet',  'as needed',       30, 10),
(5, 5, '1 tablet',  'twice daily',     30, 60),
(6, 6, '1 tablet',  'once daily',      30, 30);

INSERT INTO lab_test (test_name, sample_type, reference_range, unit, price) VALUES
('Malaria RDT',           'Blood', 'Negative',  NULL,     1500.00),
('Full Blood Count',      'Blood', 'Varies',    NULL,     4000.00),
('HbA1c',                 'Blood', '4.0 - 5.6', '%',      6500.00),
('Lipid Profile',         'Blood', 'Varies',    'mmol/L', 8000.00),
('Urinalysis',            'Urine', 'Normal',    NULL,     2000.00),
('Electrocardiogram (ECG)','N/A',  'Normal sinus rhythm', NULL, 10000.00);

INSERT INTO lab_order (consultation_id, test_id, status, result_value, is_abnormal, requested_at, completed_at) VALUES
(1, 1, 'Completed', 'Positive',            TRUE,  '2026-10-05 09:20', '2026-10-05 09:45'),
(1, 2, 'Completed', 'Hb 11.8 g/dL',        TRUE,  '2026-10-05 09:20', '2026-10-05 11:00'),
(2, 5, 'Completed', 'Normal',              FALSE, '2026-10-05 10:15', '2026-10-05 10:50'),
(4, 6, 'Completed', 'ST depression V4-V6', TRUE,  '2026-10-06 11:20', '2026-10-06 11:40'),
(4, 4, 'Requested', NULL,                  NULL,  '2026-10-06 11:20', NULL),
(5, 3, 'Completed', '8.2',                 TRUE,  '2026-10-07 14:20', '2026-10-08 10:00'),
(6, 4, 'Collected', NULL,                  NULL,  '2026-10-12 11:15', NULL);

INSERT INTO payment (appointment_id, amount, method, status, reference, paid_at) VALUES
(1, 13600.00, 'NHIS',     'Paid',    'NHIS-CLM-0001',  '2026-10-05 11:30'),
(2, 12450.00, 'Transfer', 'Paid',    'TRF-88120931',   '2026-10-05 11:10'),
(3,  7500.00, 'NHIS',     'Paid',    'NHIS-CLM-0002',  '2026-10-06 10:15'),
(4, 25800.00, 'Card',     'Pending', NULL,              NULL),
(5, 14600.00, 'Cash',     'Paid',    'CSH-000145',     '2026-10-07 15:05'),
(8,  9350.00, 'Transfer', 'Failed',  'TRF-88120977',   NULL),
(8,  9350.00, 'Transfer', 'Paid',    'TRF-88121002',   '2026-10-12 12:40');
