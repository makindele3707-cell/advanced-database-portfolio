# ER Diagram — CareBridge Specialist Clinic

GitHub renders this diagram automatically. To export it as an image, paste the code block into https://mermaid.live and download a PNG.

```mermaid
erDiagram
    DEPARTMENT ||--o{ DOCTOR : employs
    DOCTOR ||--o{ APPOINTMENT : attends
    PATIENT ||--o{ APPOINTMENT : books
    PATIENT ||--o{ PATIENT_ALLERGY : has
    APPOINTMENT ||--o| CONSULTATION : "results in"
    APPOINTMENT ||--o{ PAYMENT : "is billed by"
    CONSULTATION ||--o{ PRESCRIPTION : produces
    PRESCRIPTION ||--|{ PRESCRIPTION_ITEM : contains
    MEDICATION ||--o{ PRESCRIPTION_ITEM : "appears in"
    CONSULTATION ||--o{ LAB_ORDER : requests
    LAB_TEST ||--o{ LAB_ORDER : "is ordered as"

    DEPARTMENT {
        int department_id PK
        varchar name UK
        smallint floor
        varchar phone_extension
    }
    DOCTOR {
        int doctor_id PK
        varchar first_name
        varchar last_name
        varchar specialisation
        int department_id FK
        varchar mdcn_number UK
        varchar email UK
        varchar phone
        date hire_date
        boolean is_active
    }
    PATIENT {
        int patient_id PK
        varchar hospital_number UK
        varchar first_name
        varchar last_name
        date date_of_birth
        char gender
        varchar blood_group
        varchar genotype
        varchar phone
        varchar email UK
        varchar address
        varchar nhis_number UK
        timestamp registered_at
    }
    PATIENT_ALLERGY {
        int patient_id PK, FK
        varchar allergen PK
        varchar severity
    }
    APPOINTMENT {
        int appointment_id PK
        int patient_id FK
        int doctor_id FK
        timestamp scheduled_at
        varchar reason
        varchar status
        timestamp created_at
    }
    CONSULTATION {
        int consultation_id PK
        int appointment_id FK, UK
        text symptoms
        varchar diagnosis
        varchar icd10_code
        text notes
        numeric weight_kg
        smallint bp_systolic
        smallint bp_diastolic
        numeric temperature_c
        timestamp recorded_at
    }
    MEDICATION {
        int medication_id PK
        varchar name
        varchar form
        varchar strength
        numeric unit_price
        int stock_quantity
    }
    PRESCRIPTION {
        int prescription_id PK
        int consultation_id FK
        timestamp issued_at
        boolean is_dispensed
    }
    PRESCRIPTION_ITEM {
        int prescription_id PK, FK
        int medication_id PK, FK
        varchar dosage
        varchar frequency
        smallint duration_days
        int quantity
    }
    LAB_TEST {
        int test_id PK
        varchar test_name UK
        varchar sample_type
        varchar reference_range
        varchar unit
        numeric price
    }
    LAB_ORDER {
        int lab_order_id PK
        int consultation_id FK
        int test_id FK
        varchar status
        varchar result_value
        boolean is_abnormal
        timestamp requested_at
        timestamp completed_at
    }
    PAYMENT {
        int payment_id PK
        int appointment_id FK
        numeric amount
        varchar method
        varchar status
        varchar reference UK
        timestamp paid_at
    }
```

## Relationship summary

| Relationship | Cardinality | Business rule |
|---|---|---|
| Department – Doctor | 1 : N | Every doctor belongs to one department; a department can have many doctors. |
| Patient – Appointment | 1 : N | A patient can book many appointments over time. |
| Doctor – Appointment | 1 : N | A doctor sees many patients, but only one per time slot. |
| Appointment – Consultation | 1 : 0..1 | Only appointments that actually happen produce a consultation record. |
| Appointment – Payment | 1 : N | A bill can have several payment attempts (e.g. a failed transfer, then a successful one). |
| Consultation – Prescription | 1 : N | A consultation may produce zero or more prescriptions. |
| Prescription – Medication | M : N | Resolved through PRESCRIPTION_ITEM, which stores dosage and quantity. |
| Consultation – Lab Test | M : N | Resolved through LAB_ORDER, which stores status and result. |
| Patient – Allergy | 1 : N | Allergies are a multi-valued attribute, stored in their own table. |
