# MIT 8103 Advanced Database Systems — Final Portfolio Documentation

- **Institution:** Miva Open University — School of Postgraduate Studies (Master of Information Technology)
- **Session:** 2026/2027 Academic Session (First Semester Continuous Assessment)
- **Student Name:** Moyinoluwa Akindele, 2026/A/MIT/0350301903707
- **Selected Case Study:** CareBridge Specialist Clinic, Abuja
- **GitHub Repository Link:** `https://github.com/makindele3707-cell/advanced-database-portfolio`

---

## 1. Selected Organisation and Case Study Statement

**CareBridge Specialist Clinic, Abuja** is a mid-sized multi-specialty outpatient clinic operating across five core units: **General Medicine, Paediatrics, Cardiology, Obstetrics & Gynaecology, and a Diagnostic Laboratory**, supported by an in-house pharmacy and billing unit.

- **Database Users:** Front-desk receptionists (patient registration and appointment scheduling), specialist doctors (clinical consultations, diagnoses, prescriptions, and lab requests), medical laboratory scientists (specimen tracking and test results), pharmacists (dispensing and stock control), billing officers (cash, POS card, bank transfer, and NHIS claims), and clinic management.
- **Major Data Stored:** Departments, doctors (with MDCN licence numbers), patients (with hospital and NHIS numbers), patient allergies, appointments, clinical consultations and vital signs, pharmacy medications, prescriptions and line items, lab test catalogues and orders, semi-structured clinical telemetry documents (`JSONB`), and payment records.
- **Key Database Operations:** Registering patients and recording allergies, booking conflict-free appointments, recording diagnoses with WHO ICD-10 codes, ordering and completing laboratory investigations, prescribing and atomically dispensing medications, settling multi-method bills, and generating clinical/financial reports.

---

## 2. Summary of the Five Portfolio Activities

### Portfolio 1: Database Design and Modelling
- **Implementation:** Designed and implemented a 12-table normalised relational schema (`schema.sql`) in PostgreSQL covering `department`, `doctor`, `patient`, `patient_allergy`, `appointment`, `consultation`, `medication`, `prescription`, `prescription_item`, `lab_test`, `lab_order`, and `payment`.
- **Normalisation (1NF to 3NF/BCNF):** Eliminated repeating groups from flat paper visit records into `patient_allergy`, `prescription_item`, and `lab_order` (1NF); separated catalogue attributes into `medication` and `lab_test` to remove partial dependencies on composite keys (2NF); and isolated departmental metadata into `department` to eliminate transitive dependencies (3NF/BCNF).
- **Business Rule Constraints & Verification:** Enforced clinical rules at the database layer, including `uq_doctor_slot UNIQUE (doctor_id, scheduled_at)` to prevent doctor double-booking, `CHECK (stock_quantity >= 0)` on medications, valid genotype/blood group checks, and `chk_result_when_completed` on lab orders. Executed `constraint-tests.sql` to verify that all 7 invalid operations were rejected by PostgreSQL.

### Portfolio 2: Query Processing and Optimisation
- **Analytical Queries (`queries.sql`):** Developed four multi-table analytical queries: (1) full patient medical history with aggregated prescriptions using `STRING_AGG`, (2) departmental revenue and visit completion breakdown using conditional `FILTER` aggregation, (3) abnormal lab result turnaround time in minutes, and (4) pharmacy inventory valuation.
- **Execution Plan Benchmarking (`optimisation.sql`):** Evaluated a frequent clinical query retrieving completed appointments for a patient ordered by date (`WHERE patient_id = 1 AND status = 'Completed' ORDER BY scheduled_at DESC`) across 5,010 rows using `EXPLAIN (ANALYZE, BUFFERS)`.
- **Performance Results:**
  - *Before Indexing:* PostgreSQL used a `Seq Scan on appointment` (plan cost `166.82..168.17`), scanning the entire table and discarding `4,509` non-matching rows with an execution time of **`0.346 ms`**.
  - *After Indexing:* Created a composite B-Tree index `idx_appointment_patient_status ON appointment (patient_id, status, scheduled_at DESC)` alongside a partial index `idx_lab_order_abnormal_completed`. The query planner switched to a `Bitmap Index Scan` + `Bitmap Heap Scan` (plan cost `117.66..119.02`), eliminating all `4,509` filtered rows and reducing execution time to **`0.241 ms`** (a **30.3% speedup**).

### Portfolio 3: Transactions and Concurrency Control
- **ACID Transactions (`transactions.sql`):**
  1. *Atomic Commit:* Wrapped pharmacy stock deduction (`medication_id = 8`), prescription dispensing (`prescription_id = 4`), and POS card settlement (`payment_id = 4`) inside a single `BEGIN ... COMMIT` block.
  2. *Constraint-Triggered Rollback:* Attempted to record a payment and deduct 50 Salbutamol inhalers when only 40 were in stock. The `CHECK (stock_quantity >= 0)` violation aborted the transaction, and `ROLLBACK` ensured the preceding payment row (`POS-FAIL-999`) was completely discarded.
  3. *Partial Rollback (`SAVEPOINT`):* Used `SAVEPOINT after_fbc_order` and `ROLLBACK TO SAVEPOINT` during a consultation to undo an accidental ECG lab request while committing the valid Full Blood Count request.
- **Isolation & Concurrency (`concurrency-demo.sql`):** Demonstrated `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ` to prevent non-repeatable and phantom reads during financial audits, and implemented pessimistic row-level locking (`SELECT ... FOR UPDATE`) on `medication` (verified via `pg_locks`) to prevent the Lost Update race condition when two pharmacists dispense from the same drug stock concurrently.

### Portfolio 4: NoSQL and Advanced Data Models
- **Polyglot Persistence Design (`nosql-implementation.sql`):** While core billing, inventory, and scheduling require normalized 3NF tables, specialist clinical notes and medical device outputs vary widely by department. Implemented two NoSQL structures in PostgreSQL:
  1. *Document Model (`clinical_encounter_doc`):* Stored polymorphic `JSONB` clinical documents for General Medicine (serial vital signs and FBC panels), Obstetrics & Gynaecology (ANC gravida/para and fetal heart rate assessments), and Cardiology (12-lead Schiller ECG telemetry with `PR`/`QRS`/`QTc` intervals and ST-segment findings). Indexed the collection with a **GIN (Generalized Inverted Index)** (`idx_encounter_doc_gin`) to accelerate `@>` containment queries and used `jsonb_set` for partial sub-document updates.
  2. *Key-Value Model (`triage_kv_cache`):* Implemented an $O(1)$ key-value lookup table keyed by `triage:<hospital_number>` with TTL expiration (`expires_at`) for the waiting-room triage display board.

### Portfolio 5: Distributed and Cloud Database Exercise
- **Multi-Branch Sharding & Replication (`distributed-sharding-replication.sql`):** Modelled CareBridge Clinic's expansion across three Abuja locations (**Wuse II HQ**, **Gwarinpa**, and **Kubwa**).
  1. *Declarative Horizontal Partitioning (Sharding):* Partitioned `distributed_appointment` using `PARTITION BY LIST (branch_code)` into three physical branch shards (`appointment_shard_wuse_hq`, `appointment_shard_gwarinpa`, `appointment_shard_kubwa`). Verified physical shard routing via `tableoid::regclass` and proved single-shard **partition pruning** via `EXPLAIN (COSTS OFF)` when querying Gwarinpa appointments.
  2. *Replication & CAP Trade-offs:* Configured a logical replication publication (`CREATE PUBLICATION carebridge_hq_publication FOR TABLE department, doctor, medication, lab_test`) and documented a hybrid cloud architecture: **Synchronous Multi-AZ replication** ($\text{RPO} = 0$, strong **CP** consistency) for life-critical patient allergies, prescriptions, and payments, paired with **Asynchronous Read Replicas** (**AP** eventual consistency) for branch reporting and historical lookups.

---

## 3. Individual Technical Reflection

Building the CareBridge Specialist Clinic portfolio across all five stages connected theoretical database concepts to practical engineering decisions:
1. **Schema & Normalisation vs. Real-World Constraints:** Designing Portfolio 1 showed that 3NF/BCNF eliminates redundancy, but clinical reliability equally depends on declarative `CHECK`, `UNIQUE`, and `ON DELETE RESTRICT` rules so invalid clinical states cannot enter the database even if application validation fails.
2. **Cost-Based Query Planning:** In Portfolio 2, inspecting `EXPLAIN (ANALYZE, BUFFERS)` taught me why PostgreSQL chooses a `Seq Scan` on small tables and switches to a `Bitmap Index Scan` when a predicate matches ~10% of a larger table (501 of 5,010 rows), avoiding random heap I/O while eliminating 4,509 unnecessary row evaluations.
3. **Concurrency & Architectural Trade-Offs:** Portfolios 3, 4, and 5 demonstrated that no single storage pattern fits every hospital workflow. Combining strict relational ACID locking (`SELECT ... FOR UPDATE`) for pharmacy stock, schema-flexible `JSONB` documents with `GIN` indexes for specialist telemetry, and list-partitioned shards with synchronous/asynchronous replication gives the clinic both clinical safety and horizontal scalability.

---

## 4. AI Use Declaration & References

### AI Use Declaration
- **AI Tools Used:** Claude (Anthropic) and Gemini (Google).
- **What the Tools Were Used For:** Assisting with SQL script scaffolding, generating synthetic benchmark rows for query optimisation, formatting Mermaid ER/architecture diagrams, and structuring documentation.
- **How Output Was Reviewed, Tested, and Verified:** Every SQL script and query was executed locally against my PostgreSQL `clinic` database using `psql`. I verified all constraint failures, inspected `pg_locks` and `pg_publication_tables`, captured terminal screenshots of all outputs, and reconciled the performance analysis numbers directly with my recorded `EXPLAIN ANALYZE` execution plans.

### References
1. Silberschatz, A., Korth, H. F., & Sudarshan, S. (2019). *Database System Concepts* (7th ed.). McGraw-Hill Education.
2. Connolly, T., & Begg, C. (2015). *Database Systems: A Practical Approach to Design, Implementation, and Management* (6th ed.). Pearson.
3. PostgreSQL Global Development Group. (2026). *PostgreSQL 18 Documentation*. https://www.postgresql.org/docs/18/
4. Kleppmann, M. (2017). *Designing Data-Intensive Applications*. O'Reilly Media.