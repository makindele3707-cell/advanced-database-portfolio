# Portfolio 4 — NoSQL and Advanced Data Models

## Overview

This module designs and implements **Document** and **Key-Value** NoSQL data models for **CareBridge Specialist Clinic, Abuja**, demonstrating how polyglot persistence combines strict relational integrity for billing/inventory with schema-flexible NoSQL storage for specialist clinical notes, medical device telemetry, and real-time triage queues.

## Files in this folder

| File | Purpose |
|---|---|
| `nosql-implementation.sql` | Implements the JSONB Document store (with `GIN` inverted indexing) and Key-Value triage cache in PostgreSQL |
| `sample-documents.json` | Sample polymorphic JSON clinical encounter documents across General Medicine, Obstetrics & Gynaecology, and Cardiology |
| `screenshots/` | Execution output of document containment queries (`@>`), nested path extraction, `jsonb_set` partial updates, and key-value lookups |

## 1. Why NoSQL is Suitable for Clinical Telemetry & Specialist Notes

In Portfolio 1, the relational `consultation` table stored shared core attributes (`symptoms`, `diagnosis`, `icd10_code`, `weight_kg`, `bp_systolic`, `temperature_c`). However, each clinical department at CareBridge captures deeply nested, department-specific observations:

- **Obstetrics & Gynaecology:** Gravida/para history, gestational age, fundal height, fetal heart rate, and presentation.
- **Cardiology:** 12-lead ECG machine telemetry (`PR`, `QRS`, `QTc` intervals in milliseconds, ST-segment findings, device metadata).
- **General Medicine & Lab:** Serial vital sign arrays recorded across observation hours and multi-parameter haematology panels (`Hb`, `WBC`, `Platelets`).

Forcing these polymorphic structures into relational tables would require either dozens of sparse `NULL` columns on `consultation`, an unwieldy Entity-Attribute-Value (EAV) anti-pattern, or a proliferation of department-specific tables.

## 2. Implemented NoSQL Data Models (`nosql-implementation.sql`)

### A. Document Model (`clinical_encounter_doc`)
- Stores self-contained, hierarchical JSONB clinical documents linked to `consultation_id` and `patient_hospital_no`.
- Indexed with a **GIN (Generalized Inverted Index)** (`CREATE INDEX idx_encounter_doc_gin ON clinical_encounter_doc USING GIN (encounter_doc)`), enabling fast sub-document containment searches (`@>`) without full collection scans.
- Supports partial in-place document mutation via `jsonb_set` (e.g. updating a nested Cardiology referral booking status without rewriting unrelated fields).

### B. Key-Value Model (`triage_kv_cache`)
- Models an $O(1)$ key-value lookup cache keyed by `triage:<hospital_number>` with a Time-To-Live (`expires_at`) timestamp for the clinic's live waiting-room display board.

## 3. Relational vs. NoSQL Suitability Comparison at CareBridge Clinic

| Workload | Chosen Model | Justification |
|---|---|---|
| **Appointments, Billing & Pharmacy Stock** | Relational (3NF/BCNF) | Requires multi-table ACID transactions, foreign keys, and strict `CHECK` constraints (`stock_quantity >= 0`). |
| **Specialist Encounter Notes & ECG/Lab Telemetry** | Document Model (`JSONB` + `GIN`) | Highly polymorphic, nested arrays/objects per medical specialty; read and written as a single patient encounter aggregate. |
| **Live Waiting-Room Triage Board** | Key-Value Model | Ephemeral state looked up by a single key (`triage:CBC-2026-00005`) with automatic TTL expiration after the visit ends. |

## Reflection

Designing the NoSQL layer alongside the relational schema demonstrated that relational and NoSQL databases are complementary rather than mutually exclusive. Keeping core patient identity, appointments, and financial payments in normalised relational tables preserves referential integrity, while storing variable clinical assessments as indexed JSONB documents eliminates schema migrations whenever a department introduces a new diagnostic device or assessment template.