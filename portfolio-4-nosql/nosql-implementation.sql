-- =====================================================================
-- CareBridge Specialist Clinic — NoSQL Document & Key-Value Models
-- MIT 8103 Advanced Database Systems — Portfolio 4
-- Run: psql -U postgres -d clinic -f nosql-implementation.sql
-- =====================================================================

DROP TABLE IF EXISTS clinical_encounter_doc, triage_kv_cache CASCADE;

-- ---------------------------------------------------------------------
-- 1. DOCUMENT MODEL: Semi-structured Clinical Encounter & Lab Telemetry
-- Different departments (Cardiology, Obstetrics, Paediatrics, Lab) record
-- vastly different nested clinical payloads per visit.
-- ---------------------------------------------------------------------
CREATE TABLE clinical_encounter_doc (
    doc_id          SERIAL       PRIMARY KEY,
    consultation_id INT          REFERENCES consultation(consultation_id) ON DELETE SET NULL,
    patient_hospital_no VARCHAR(15) NOT NULL,
    department_name VARCHAR(80)  NOT NULL,
    encounter_doc   JSONB        NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Create a GIN (Generalized Inverted Index) for fast NoSQL document queries
CREATE INDEX idx_encounter_doc_gin ON clinical_encounter_doc USING GIN (encounter_doc);

-- Insert polymorphic clinical documents across different departments
INSERT INTO clinical_encounter_doc (consultation_id, patient_hospital_no, department_name, encounter_doc) VALUES
(1, 'CBC-2026-00001', 'General Medicine', '{
    "visit_type": "Outpatient Acute",
    "presenting_complaints": ["high fever", "frontal headache", "arthralgia"],
    "vitals_series": [
        {"time": "09:05", "temp_c": 38.9, "bp": "120/80", "pulse_bpm": 98},
        {"time": "10:30", "temp_c": 37.6, "bp": "118/78", "pulse_bpm": 84}
    ],
    "lab_panel": {
        "malaria_rdt": {"parasite": "P. falciparum", "result": "Positive"},
        "fbc_parameters": {"hb_g_dl": 11.8, "wbc_10e9_l": 6.4, "platelets_10e9_l": 142}
    },
    "clinical_tags": ["malaria", "act-therapy", "follow-up-required"]
}'::jsonb),

(2, 'CBC-2026-00002', 'Obstetrics & Gynaecology', '{
    "visit_type": "Antenatal Care (ANC)",
    "obstetric_history": {
        "gravida": 2,
        "para": 1,
        "gestational_age_weeks": 24,
        "lmp_date": "2026-04-19",
        "edd_date": "2027-01-24"
    },
    "fetal_assessment": {
        "fundal_height_cm": 24,
        "fetal_heart_rate_bpm": 146,
        "presentation": "Cephalic",
        "fetal_movement": "Active"
    },
    "clinical_tags": ["antenatal", "second-trimester", "routine-anc"]
}'::jsonb),

(4, 'CBC-2026-00005', 'Cardiology', '{
    "visit_type": "Specialist Cardiac Review",
    "cardiac_risk_factors": ["hypertension", "age > 60", "exertional dyspnoea"],
    "ecg_telemetry": {
        "device_id": "SCHILLER-AT102-ABJ",
        "rhythm": "Sinus rhythm",
        "ventricular_rate_bpm": 88,
        "intervals_ms": {"pr": 164, "qrs": 92, "qt_corrected": 418},
        "st_segment_findings": ["ST depression 1.5mm in leads V4-V6"],
        "critical_alert": true
    },
    "referral": {"target_unit": "Cardiac Stress Lab", "priority": "Urgent"},
    "clinical_tags": ["angina", "abnormal-ecg", "cardiology-priority"]
}'::jsonb);

\echo '=== Query 1: Document Containment Query (@>) using GIN Index ==='
\echo '--- Find all clinical documents tagged with "abnormal-ecg" or critical ECG alert ---'
SELECT doc_id,
       patient_hospital_no,
       department_name,
       encounter_doc->'ecg_telemetry'->>'rhythm' AS ecg_rhythm,
       encounter_doc->'ecg_telemetry'->'st_segment_findings' AS st_findings,
       encounter_doc->'referral'->>'priority' AS referral_priority
FROM clinical_encounter_doc
WHERE encounter_doc @> '{"ecg_telemetry": {"critical_alert": true}}';

\echo '=== Query 2: Extracting Nested Array & Object Attributes Across Polymorphic Schemas ==='
SELECT doc_id,
       patient_hospital_no,
       department_name,
       encounter_doc->>'visit_type' AS visit_type,
       COALESCE(
           encounter_doc->'fetal_assessment'->>'fetal_heart_rate_bpm',
           encounter_doc->'ecg_telemetry'->>'ventricular_rate_bpm',
           encounter_doc->'vitals_series'->0->>'pulse_bpm'
       ) AS recorded_heart_rate_bpm,
       encounter_doc->'clinical_tags' AS tags
FROM clinical_encounter_doc
ORDER BY doc_id;

\echo '=== Query 3: Partial Document Mutation using jsonb_set (Adding Follow-up Note) ==='
UPDATE clinical_encounter_doc
SET encounter_doc = jsonb_set(
    encounter_doc,
    '{referral,booking_status}',
    '"Confirmed for 2026-10-09"'::jsonb,
    TRUE
)
WHERE doc_id = 3
RETURNING doc_id, patient_hospital_no, encounter_doc->'referral' AS updated_referral_subdocument;


-- ---------------------------------------------------------------------
-- 2. KEY-VALUE MODEL: Live Triage Queue & Session Cache
-- Models a fast key-value lookup store (similar to Redis) keyed by
-- patient hospital number with TTL expiry for active waiting-room status.
-- ---------------------------------------------------------------------
CREATE TABLE triage_kv_cache (
    cache_key       VARCHAR(60)  PRIMARY KEY,
    cache_value     JSONB        NOT NULL,
    expires_at      TIMESTAMP    NOT NULL
);

INSERT INTO triage_kv_cache (cache_key, cache_value, expires_at) VALUES
('triage:CBC-2026-00001', '{"queue_no": "A-014", "triage_band": "Amber", "assigned_room": "Consult-1", "spo2_pct": 98}', NOW() + INTERVAL '2 hours'),
('triage:CBC-2026-00005', '{"queue_no": "C-002", "triage_band": "Red",   "assigned_room": "Cardio-2",  "spo2_pct": 94}', NOW() + INTERVAL '2 hours'),
('triage:CBC-2026-00002', '{"queue_no": "O-007", "triage_band": "Green", "assigned_room": "ANC-1",     "spo2_pct": 99}', NOW() + INTERVAL '2 hours');

\echo '=== Query 4: Key-Value O(1) Primary Key Lookup for Waiting Room Board ==='
SELECT cache_key,
       cache_value->>'queue_no' AS queue_ticket,
       cache_value->>'triage_band' AS priority_band,
       cache_value->>'assigned_room' AS room,
       cache_value->>'spo2_pct' AS spo2_percent
FROM triage_kv_cache
WHERE cache_key = 'triage:CBC-2026-00005'
  AND expires_at > NOW();