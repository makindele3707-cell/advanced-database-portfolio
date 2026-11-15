-- =====================================================================
-- CareBridge Specialist Clinic — Distributed Sharding & Replication Setup
-- MIT 8103 Advanced Database Systems — Portfolio 5
-- Run: psql -U postgres -d clinic -f distributed-sharding-replication.sql
-- =====================================================================

DROP PUBLICATION IF EXISTS carebridge_hq_publication;
DROP TABLE IF EXISTS distributed_appointment CASCADE;

-- ---------------------------------------------------------------------
-- 1. HORIZONTAL PARTITIONING (SHARDING BY CLINIC BRANCH)
-- As CareBridge expands from Wuse II HQ to Gwarinpa and Kubwa branches,
-- appointments are horizontally partitioned by branch_code so each branch
-- shard can reside on dedicated storage/nodes while presenting a single
-- logical table to the application.
-- ---------------------------------------------------------------------
CREATE TABLE distributed_appointment (
    appointment_id  SERIAL,
    branch_code     VARCHAR(12)  NOT NULL CHECK (branch_code IN ('WUSE_HQ', 'GWARINPA', 'KUBWA')),
    patient_id      INT          NOT NULL,
    doctor_id       INT          NOT NULL,
    scheduled_at    TIMESTAMP    NOT NULL,
    status          VARCHAR(12)  NOT NULL DEFAULT 'Scheduled',
    PRIMARY KEY (branch_code, appointment_id)
) PARTITION BY LIST (branch_code);

-- Create the 3 regional branch shards (partitions)
CREATE TABLE appointment_shard_wuse_hq
    PARTITION OF distributed_appointment FOR VALUES IN ('WUSE_HQ');

CREATE TABLE appointment_shard_gwarinpa
    PARTITION OF distributed_appointment FOR VALUES IN ('GWARINPA');

CREATE TABLE appointment_shard_kubwa
    PARTITION OF distributed_appointment FOR VALUES IN ('KUBWA');

-- Seed multi-branch appointments across the 3 Abuja clinic locations
INSERT INTO distributed_appointment (branch_code, patient_id, doctor_id, scheduled_at, status) VALUES
('WUSE_HQ',  1, 1, '2026-11-10 09:00', 'Completed'),
('WUSE_HQ',  4, 2, '2026-11-10 10:30', 'Completed'),
('WUSE_HQ',  8, 4, '2026-11-11 11:00', 'Scheduled'),
('GWARINPA', 2, 5, '2026-11-10 09:30', 'Completed'),
('GWARINPA', 7, 3, '2026-11-11 14:00', 'Scheduled'),
('KUBWA',    5, 4, '2026-11-10 12:00', 'Completed'),
('KUBWA',    3, 3, '2026-11-12 09:00', 'Scheduled');

\echo '=== 1. Verify Physical Shard Placement Using tableoid::regclass ==='
SELECT tableoid::regclass AS physical_shard_table,
       branch_code,
       appointment_id,
       patient_id,
       doctor_id,
       scheduled_at,
       status
FROM distributed_appointment
ORDER BY branch_code, appointment_id;

\echo '=== 2. Verify Partition Pruning (Single-Shard Query Routing) ==='
\echo '--- Querying ONLY Gwarinpa branch skips Wuse HQ and Kubwa shards completely ---'
EXPLAIN (COSTS OFF)
SELECT appointment_id, patient_id, doctor_id, scheduled_at, status
FROM distributed_appointment
WHERE branch_code = 'GWARINPA';


-- ---------------------------------------------------------------------
-- 2. LOGICAL REPLICATION & WAL CONFIGURATION VERIFICATION
-- Create a replication publication for reference tables (doctor, medication,
-- lab_test) replicated from Wuse II HQ to regional read-replicas.
-- ---------------------------------------------------------------------
CREATE PUBLICATION carebridge_hq_publication
    FOR TABLE department, doctor, medication, lab_test;

\echo '=== 3. Verify Replication Publication & Published Tables ==='
SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete
FROM pg_publication
WHERE pubname = 'carebridge_hq_publication';

SELECT pubname, schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'carebridge_hq_publication'
ORDER BY tablename;

\echo '=== 4. Inspect Active WAL & Replication Settings ==='
SELECT name, setting, short_desc
FROM pg_settings
WHERE name IN ('wal_level', 'max_wal_senders', 'max_replication_slots', 'synchronous_commit')
ORDER BY name;