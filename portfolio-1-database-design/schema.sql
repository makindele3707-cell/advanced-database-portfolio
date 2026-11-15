-- =====================================================================
-- CareBridge Specialist Clinic — Relational Schema
-- MIT 8103 Advanced Database Systems — Portfolio 1
-- DBMS: PostgreSQL 16
-- Run:  psql -U postgres -d clinic -f schema.sql
-- =====================================================================

DROP TABLE IF EXISTS payment, lab_order, lab_test, prescription_item, prescription,
    medication, consultation, appointment, patient_allergy, patient, doctor,
    department CASCADE;

-- ---------------------------------------------------------------------
-- 1. DEPARTMENT: clinical units (e.g. Cardiology, Paediatrics)
-- ---------------------------------------------------------------------
CREATE TABLE department (
    department_id   SERIAL       PRIMARY KEY,
    name            VARCHAR(80)  NOT NULL UNIQUE,
    floor           SMALLINT     CHECK (floor BETWEEN 0 AND 10),
    phone_extension VARCHAR(10)
);

-- ---------------------------------------------------------------------
-- 2. DOCTOR: each doctor belongs to exactly one department
-- ---------------------------------------------------------------------
CREATE TABLE doctor (
    doctor_id       SERIAL       PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    specialisation  VARCHAR(80)  NOT NULL,
    department_id   INT          NOT NULL REFERENCES department(department_id)
                                 ON UPDATE CASCADE ON DELETE RESTRICT,
    mdcn_number     VARCHAR(20)  NOT NULL UNIQUE,   -- Medical & Dental Council of Nigeria licence
    email           VARCHAR(120) NOT NULL UNIQUE,
    phone           VARCHAR(20)  NOT NULL,
    hire_date       DATE         NOT NULL DEFAULT CURRENT_DATE,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------
-- 3. PATIENT
-- ---------------------------------------------------------------------
CREATE TABLE patient (
    patient_id      SERIAL       PRIMARY KEY,
    hospital_number VARCHAR(15)  NOT NULL UNIQUE,   -- e.g. CBC-2026-00001
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    date_of_birth   DATE         NOT NULL CHECK (date_of_birth <= CURRENT_DATE),
    gender          CHAR(1)      NOT NULL CHECK (gender IN ('M', 'F')),
    blood_group     VARCHAR(3)   CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    genotype        VARCHAR(2)   CHECK (genotype IN ('AA','AS','SS','AC','SC')),
    phone           VARCHAR(20)  NOT NULL,
    email           VARCHAR(120) UNIQUE,
    address         VARCHAR(200),
    nhis_number     VARCHAR(20)  UNIQUE,            -- NULL if patient pays out of pocket
    registered_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 4. PATIENT_ALLERGY: multi-valued attribute moved out of PATIENT (1NF)
-- ---------------------------------------------------------------------
CREATE TABLE patient_allergy (
    patient_id      INT          NOT NULL REFERENCES patient(patient_id) ON DELETE CASCADE,
    allergen        VARCHAR(80)  NOT NULL,
    severity        VARCHAR(10)  NOT NULL CHECK (severity IN ('Mild','Moderate','Severe')),
    PRIMARY KEY (patient_id, allergen)
);

-- ---------------------------------------------------------------------
-- 5. APPOINTMENT: links a patient to a doctor at a time slot
-- ---------------------------------------------------------------------
CREATE TABLE appointment (
    appointment_id  SERIAL       PRIMARY KEY,
    patient_id      INT          NOT NULL REFERENCES patient(patient_id) ON DELETE RESTRICT,
    doctor_id       INT          NOT NULL REFERENCES doctor(doctor_id)   ON DELETE RESTRICT,
    scheduled_at    TIMESTAMP    NOT NULL,
    reason          VARCHAR(200),
    status          VARCHAR(12)  NOT NULL DEFAULT 'Scheduled'
                    CHECK (status IN ('Scheduled','Completed','Cancelled','No-Show')),
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    -- A doctor cannot hold two appointments in the same slot
    CONSTRAINT uq_doctor_slot UNIQUE (doctor_id, scheduled_at)
);

-- ---------------------------------------------------------------------
-- 6. CONSULTATION: what happened during a completed appointment (1:1)
-- ---------------------------------------------------------------------
CREATE TABLE consultation (
    consultation_id SERIAL       PRIMARY KEY,
    appointment_id  INT          NOT NULL UNIQUE REFERENCES appointment(appointment_id)
                                 ON DELETE CASCADE,
    symptoms        TEXT         NOT NULL,
    diagnosis       VARCHAR(200) NOT NULL,
    icd10_code      VARCHAR(10),                    -- WHO ICD-10 code, e.g. B54 (malaria)
    notes           TEXT,
    weight_kg       NUMERIC(5,2) CHECK (weight_kg > 0),
    bp_systolic     SMALLINT     CHECK (bp_systolic  BETWEEN 50 AND 300),
    bp_diastolic    SMALLINT     CHECK (bp_diastolic BETWEEN 30 AND 200),
    temperature_c   NUMERIC(4,1) CHECK (temperature_c BETWEEN 30 AND 45),
    recorded_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 7. MEDICATION: pharmacy stock
-- ---------------------------------------------------------------------
CREATE TABLE medication (
    medication_id   SERIAL       PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    form            VARCHAR(20)  NOT NULL CHECK (form IN ('Tablet','Capsule','Syrup','Injection','Cream','Inhaler')),
    strength        VARCHAR(30)  NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    stock_quantity  INT          NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    UNIQUE (name, form, strength)
);

-- ---------------------------------------------------------------------
-- 8. PRESCRIPTION (header) and 9. PRESCRIPTION_ITEM (lines)
-- ---------------------------------------------------------------------
CREATE TABLE prescription (
    prescription_id SERIAL       PRIMARY KEY,
    consultation_id INT          NOT NULL REFERENCES consultation(consultation_id) ON DELETE CASCADE,
    issued_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
    is_dispensed    BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE prescription_item (
    prescription_id INT          NOT NULL REFERENCES prescription(prescription_id) ON DELETE CASCADE,
    medication_id   INT          NOT NULL REFERENCES medication(medication_id)     ON DELETE RESTRICT,
    dosage          VARCHAR(50)  NOT NULL,          -- e.g. '2 tablets'
    frequency       VARCHAR(50)  NOT NULL,          -- e.g. 'twice daily'
    duration_days   SMALLINT     NOT NULL CHECK (duration_days > 0),
    quantity        INT          NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (prescription_id, medication_id)
);

-- ---------------------------------------------------------------------
-- 10. LAB_TEST (catalogue) and 11. LAB_ORDER (test requested + result)
-- ---------------------------------------------------------------------
CREATE TABLE lab_test (
    test_id         SERIAL       PRIMARY KEY,
    test_name       VARCHAR(100) NOT NULL UNIQUE,
    sample_type     VARCHAR(30)  NOT NULL,          -- Blood, Urine, Stool, Swab
    reference_range VARCHAR(60),
    unit            VARCHAR(20),
    price           NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE lab_order (
    lab_order_id    SERIAL       PRIMARY KEY,
    consultation_id INT          NOT NULL REFERENCES consultation(consultation_id) ON DELETE CASCADE,
    test_id         INT          NOT NULL REFERENCES lab_test(test_id) ON DELETE RESTRICT,
    status          VARCHAR(12)  NOT NULL DEFAULT 'Requested'
                    CHECK (status IN ('Requested','Collected','Completed','Cancelled')),
    result_value    VARCHAR(60),
    is_abnormal     BOOLEAN,
    requested_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMP,
    -- A completed test must have a result and a completion time
    CONSTRAINT chk_result_when_completed
        CHECK (status <> 'Completed' OR (result_value IS NOT NULL AND completed_at IS NOT NULL)),
    CONSTRAINT chk_completed_after_requested
        CHECK (completed_at IS NULL OR completed_at >= requested_at)
);

-- ---------------------------------------------------------------------
-- 12. PAYMENT: bills settled against an appointment
-- ---------------------------------------------------------------------
CREATE TABLE payment (
    payment_id      SERIAL       PRIMARY KEY,
    appointment_id  INT          NOT NULL REFERENCES appointment(appointment_id) ON DELETE RESTRICT,
    amount          NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    method          VARCHAR(10)  NOT NULL CHECK (method IN ('Cash','Card','Transfer','NHIS')),
    status          VARCHAR(10)  NOT NULL DEFAULT 'Pending'
                    CHECK (status IN ('Pending','Paid','Refunded','Failed')),
    reference       VARCHAR(40)  UNIQUE,            -- bank/POS reference
    paid_at         TIMESTAMP
);
