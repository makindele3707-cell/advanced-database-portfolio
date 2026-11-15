# Normalisation — CareBridge Specialist Clinic

## Starting point: the unnormalised clinic record

Before designing tables, I looked at how a paper visit record at a clinic might look if it were typed straight into one big table:

| visit_id | patient_name | patient_phone | allergies | doctor_name | department | dept_floor | visit_date | diagnosis | medicines | tests_and_results |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Emeka Nwosu | 0805111... | Penicillin, Peanuts | Dr Okafor | General Medicine | 1 | 2026-10-05 | Malaria | Coartem 4 tabs x2; Paracetamol 2 tabs x3 | Malaria RDT: Positive; FBC: Hb 11.8 |

This single table has several problems:

- **Repeating groups:** `allergies`, `medicines` and `tests_and_results` hold lists inside one cell, so you can't query them properly (for example, "find every patient allergic to penicillin").
- **Update anomaly:** Emeka's phone number is copied into every visit row. If he changes his number, every row must be updated, or the data becomes inconsistent.
- **Insertion anomaly:** A new doctor can't be recorded until they see a patient, because doctor details only exist inside visit rows.
- **Deletion anomaly:** Deleting the only visit for a department would also delete the fact that the department is on floor 1.

## First Normal Form (1NF)

**Rule:** Every cell holds a single (atomic) value, and there are no repeating groups.

**What I did:**
- Moved allergies into **PATIENT_ALLERGY**, one row per (patient, allergen).
- Moved medicines into **PRESCRIPTION_ITEM**, one row per (prescription, medication).
- Moved tests into **LAB_ORDER**, one row per test requested.
- Split names into `first_name` and `last_name` so each column holds one fact.

## Second Normal Form (2NF)

**Rule:** The table is in 1NF, and every non-key column depends on the *whole* primary key, not just part of it. This only matters for tables with composite keys.

**Example:** After 1NF, the prescription lines could look like this, with key `(prescription_id, medication_id)`:

| prescription_id | medication_id | medication_name | unit_price | dosage | quantity |
|---|---|---|---|---|---|

Here `medication_name` and `unit_price` depend only on `medication_id`, which is part of the key. That's a **partial dependency**, so if the price of amoxicillin changes, every prescription line containing it would need updating.

**What I did:** Moved medication details into their own **MEDICATION** table. **PRESCRIPTION_ITEM** now keeps only the facts that depend on the full key (`dosage`, `frequency`, `duration_days`, `quantity`). The same reasoning applied to **LAB_ORDER** and **LAB_TEST**: the test name, price and reference range live in **LAB_TEST**, not in each order.

**PATIENT_ALLERGY** is also in 2NF, because `severity` depends on both the patient *and* the allergen (the same allergen can be mild for one patient and severe for another).

## Third Normal Form (3NF)

**Rule:** The table is in 2NF, and no non-key column depends on another non-key column (no **transitive dependencies**).

**Example:** An early version of the DOCTOR table looked like this:

| doctor_id | name | department_name | department_floor | department_extension |
|---|---|---|---|---|

Here `doctor_id → department_name → department_floor`. The floor depends on the department, not on the doctor. If Cardiology moved to floor 3, every cardiologist's row would need changing.

**What I did:** Created a separate **DEPARTMENT** table, and DOCTOR now stores only `department_id` as a foreign key.

**Similar decisions:**
- **APPOINTMENT** stores only `patient_id` and `doctor_id`, not patient or doctor names.
- **PAYMENT** links to the appointment rather than copying patient details.
- **CONSULTATION** links to the appointment, so the patient, doctor and date are found through that link rather than stored again.

## Boyce–Codd Normal Form (BCNF) check

BCNF requires that every determinant (a column that decides another column's value) is a candidate key. I checked the tables with more than one unique column:

- **PATIENT:** `patient_id`, `hospital_number`, `email` and `nhis_number` are all unique, so each is a candidate key. Every determinant is a candidate key, so the table is in BCNF.
- **DOCTOR:** `doctor_id`, `mdcn_number` and `email` are candidate keys. Also BCNF.
- **APPOINTMENT:** `(doctor_id, scheduled_at)` is a second candidate key, enforced by the `uq_doctor_slot` constraint. Also BCNF.

The schema therefore meets **3NF and BCNF**.

## Deliberate design decisions

- **Lab result stored in LAB_ORDER:** Each order has at most one result, so a separate result table would only add a join. A `CHECK` constraint makes sure a completed order always has a result.
- **Vital signs stored in CONSULTATION:** Weight, blood pressure and temperature are measured once per visit, so they depend fully on the consultation.
- **Payment amount not computed from items:** The amount is recorded as charged at the time of payment, which keeps a historical record even if prices change later. This is a standard practice in billing systems, not a normalisation violation, because the stored value is a historical fact rather than a derived one.
- **Age not stored:** Only `date_of_birth` is stored, because age changes every year and can be calculated in queries.
