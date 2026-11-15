# Advanced Database Systems Portfolio

**Course:** MIT 8103 Advanced Database Systems, Miva Open University (2026/2027, First Semester)  
**Student:** Moyinoluwa Akindele, 2026/A/MIT/0350301903707
**Case study:** CareBridge Specialist Clinic, Abuja (fictional)

## Selected organisation

CareBridge Specialist Clinic is a fictional outpatient clinic in Abuja with five departments: General Medicine, Paediatrics, Cardiology, Obstetrics & Gynaecology, and a Laboratory. Patients book appointments with doctors, who record consultations, order lab tests and issue prescriptions from the clinic's pharmacy. Bills are paid by cash, card, transfer or NHIS.

- **Users:** front-desk staff, doctors, lab scientists, pharmacists, billing officers and management.
- **Major data:** patients, allergies, doctors, departments, appointments, consultations, prescriptions, medications, lab tests and results, payments.
- **Key operations:** register patients, book appointments, record diagnoses, prescribe and dispense drugs, order lab tests, process payments, retrieve patient history.

## Portfolio contents

| Portfolio                            | Folder                                                                        | Status      |
| ------------------------------------ | ----------------------------------------------------------------------------- | ----------- |
| 1. Database Design and Modelling     | [portfolio-1-database-design](portfolio-1-database-design/)                   | ✅ Complete |
| 2. Query Processing and Optimisation | [portfolio-2-query-optimisation](portfolio-2-query-optimisation/)             | ✅ Complete |
| 3. Transactions and Concurrency      | [portfolio-3-transactions-concurrency](portfolio-3-transactions-concurrency/) | ✅ Complete |
| 4. NoSQL and Advanced Data Models    | [portfolio-4-nosql](portfolio-4-nosql/)                                       | ✅ Complete |
| 5. Distributed and Cloud Databases   | [portfolio-5-distributed-cloud](portfolio-5-distributed-cloud/)               | ✅ Complete |

## Tools

- **PostgreSQL** (relational database, `JSONB` document store, declarative partitioning, and logical replication)
- **`psql`** (interactive command-line client for executing SQL scripts, transactions, and `EXPLAIN (ANALYZE, BUFFERS)`)
- **Mermaid** (ER and distributed cloud architecture diagrams)

## AI use declaration

In compliance with Section 11 of the MIT 8103 Continuous Assessment brief:

- **AI Tools Used:** Claude (Anthropic) and Gemini (Google).
- **Purpose of Use:** Used as a learning and structuring aid for drafting initial SQL scripts, formatting Mermaid diagrams, generating realistic synthetic test rows for query benchmarking, and structuring markdown documentation across the five portfolio modules.
- **Review, Testing, and Verification:** Every SQL script (`schema.sql`, `sample-data.sql`, `constraint-tests.sql`, `queries.sql`, `optimisation.sql`, `transactions.sql`, `concurrency-demo.sql`, `nosql-implementation.sql`, and `distributed-sharding-replication.sql`) was executed and verified directly on my PostgreSQL `clinic` database instance via `psql`. I inspected the actual `EXPLAIN (ANALYZE, BUFFERS)` execution plans, verified that all seven constraint tests failed with the expected relational integrity errors, checked lock modes in `pg_locks`, and updated the performance tables to match my actual database execution outputs.

## References

1. Silberschatz, A., Korth, H. F., & Sudarshan, S. (2019). _Database System Concepts_ (7th ed.). McGraw-Hill Education.
2. Connolly, T., & Begg, C. (2015). _Database Systems: A Practical Approach to Design, Implementation, and Management_ (6th ed.). Pearson.
3. PostgreSQL Global Development Group. (2026). _PostgreSQL Official Documentation ( Chapters on Concurrency Control, Indexes, JSON Types, Table Partitioning, and Logical Replication)_. https://www.postgresql.org/docs/
4. Kleppmann, M. (2017). _Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems_. O'Reilly Media.
