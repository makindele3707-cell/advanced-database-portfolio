# Portfolio 1 — Database Design and Modelling

## Case study

**CareBridge Specialist Clinic, Abuja** is a fictional mid-sized outpatient clinic with five departments: General Medicine, Paediatrics, Cardiology, Obstetrics & Gynaecology, and a Laboratory. It sees patients by appointment, records consultations, orders lab tests, issues prescriptions from its in-house pharmacy, and accepts payments by cash, card, bank transfer and NHIS (National Health Insurance Scheme).

| Item | Details |
|---|---|
| **Users of the database** | Front-desk staff (register patients, book appointments), doctors (record consultations, prescribe, order tests), lab scientists (record results), pharmacists (dispense drugs, manage stock), billing officers (record payments), management (reports). |
| **Major data stored** | Departments, doctors, patients and their allergies, appointments, consultations and vital signs, medications and stock, prescriptions, lab tests and results, payments. |
| **Key operations** | Register a patient, book and cancel appointments, record a diagnosis, prescribe and dispense medication, order and record lab tests, process payments, retrieve a patient's full medical history. |

## Files in this folder

| File | Purpose |
|---|---|
| `er-diagram.md` | ER diagram (Mermaid, renders on GitHub) and relationship summary |
| `schema.sql` | Creates all 12 tables with primary keys, foreign keys and constraints |
| `sample-data.sql` | Inserts fictional test data |
| `constraint-tests.sql` | Statements that deliberately break the rules, to prove the constraints work |
| `normalisation.md` | Step-by-step explanation from an unnormalised record to 3NF/BCNF |
| `screenshots/` | Evidence of the scripts running |

## How to run

Requires PostgreSQL 14 or later.

```bash
createdb clinic
psql -d clinic -f schema.sql
psql -d clinic -f sample-data.sql
psql -d clinic -f constraint-tests.sql   # every statement should fail with an error
```

## Design summary

The schema has **12 tables**. The two many-to-many relationships in the clinic are resolved with junction tables:

- **Prescription ↔ Medication** through `prescription_item` (stores dosage, frequency and quantity)
- **Consultation ↔ Lab test** through `lab_order` (stores status and result)

### Keys

- **Surrogate primary keys** (`SERIAL`) on most tables, because natural identifiers like names can change or repeat.
- **Natural keys kept as `UNIQUE`**: hospital number, NHIS number, MDCN licence number, emails and payment references.
- **Composite primary keys** on `patient_allergy (patient_id, allergen)` and `prescription_item (prescription_id, medication_id)`, which stop the same allergy or drug being recorded twice.

### Constraints and the business rules they enforce

| Constraint | Rule enforced |
|---|---|
| `UNIQUE (doctor_id, scheduled_at)` | A doctor cannot be double-booked |
| `UNIQUE (appointment_id)` on consultation | At most one consultation per appointment |
| `CHECK (stock_quantity >= 0)` | The pharmacy cannot dispense stock it doesn't have |
| `CHECK` on genotype, blood group, gender | Only valid medical values are accepted |
| `CHECK` on vital signs | Rejects impossible readings (e.g. temperature of 60 °C) |
| `chk_result_when_completed` | A lab test can't be marked completed without a result |
| `ON DELETE RESTRICT` on doctor, patient, medication | Medical history can't be lost by deleting a referenced record |
| `ON DELETE CASCADE` on allergy, prescription items | Child rows are removed when their parent is removed |

## Testing

1. Ran `schema.sql` and `sample-data.sql` on PostgreSQL 16 with no errors.
2. Ran a join across patient, appointment, doctor and consultation to confirm the relationships return the expected six diagnoses.
3. Ran `constraint-tests.sql`. All seven invalid operations were rejected with the expected constraint error (see `screenshots/`).

## Reflection

I selected CareBridge Specialist Clinic as my case study because an outpatient hospital naturally combines strict relational integrity requirements (such as patient records, medical licensing, and drug inventory) with high-concurrency workflows (appointment booking and billing) that will support the rest of the portfolio activities.

The most challenging design decision was modelling the relationship between appointments, consultations, and billing. Initially, I considered linking payments directly to consultations, but cancelled or preliminary appointments can also generate billing records, and a single visit might involve a failed bank transfer followed by a successful payment. Linking `payment` to `appointment` in a 1-to-many relationship while enforcing a 1-to-0..1 relationship between `appointment` and `consultation` kept the schema flexible without introducing redundant columns.

Going through the normalisation process from a flat clinic visit sheet to 3NF/BCNF reinforced how easily partial and transitive dependencies creep into healthcare records—especially in composite-key tables like `prescription_item`, where storing the medication's unit price or name directly would have caused update anomalies whenever pharmacy prices changed.
