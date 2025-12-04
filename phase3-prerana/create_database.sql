-- Turn on foreign key enforcement in SQLite
PRAGMA foreign_keys = ON;

------------------------------------------------
-- DROP TABLES IF YOU NEED TO RERUN THIS SCRIPT
------------------------------------------------
-- (Uncomment these if you rerun and get "table already exists" errors)

-- DROP TABLE IF EXISTS PatientImmunization;
-- DROP TABLE IF EXISTS PatientMedication;
-- DROP TABLE IF EXISTS PatientCondition;
-- DROP TABLE IF EXISTS PatientDoctor;
-- DROP TABLE IF EXISTS PatientHospital;
-- DROP TABLE IF EXISTS MedicationCondition;

-- DROP TABLE IF EXISTS Vaccine;
-- DROP TABLE IF EXISTS Medication;
-- DROP TABLE IF EXISTS Condition;
-- DROP TABLE IF EXISTS Doctor;
-- DROP TABLE IF EXISTS Hospital;
-- DROP TABLE IF EXISTS Patient;

-------------------------
-- ENTITY TABLES
-------------------------

CREATE TABLE Hospital (
    hospital_id INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    city        TEXT NOT NULL
);


CREATE TABLE Doctor (
    doctor_id   INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    specialty   TEXT,
    hospital_id INTEGER NOT NULL,
    password    TEXT,
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id)
);


CREATE TABLE Patient (
    patient_id            INTEGER PRIMARY KEY,
    medical_record_number TEXT NOT NULL,
    birth_year            INTEGER,
    gender                TEXT,
    blood_type            TEXT
);

CREATE TABLE "Condition" (
    condition_id INTEGER PRIMARY KEY,
    name         TEXT NOT NULL
);

CREATE TABLE Medication (
    medication_id INTEGER PRIMARY KEY,
    name          TEXT NOT NULL
);

CREATE TABLE Vaccine (
    vaccine_id INTEGER PRIMARY KEY,
    name       TEXT NOT NULL
);

-------------------------
-- RELATIONSHIP TABLES
-------------------------

-- Patient — Doctor (M:N)
CREATE TABLE PatientDoctor (
    patient_id INTEGER NOT NULL,
    doctor_id  INTEGER NOT NULL,
    PRIMARY KEY (patient_id, doctor_id),
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES Doctor(doctor_id)
);

-- Patient — Hospital (M:N)
CREATE TABLE PatientHospital (
    patient_id  INTEGER NOT NULL,
    hospital_id INTEGER NOT NULL,
    PRIMARY KEY (patient_id, hospital_id),
    FOREIGN KEY (patient_id)  REFERENCES Patient(patient_id),
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id)
);

-- Patient — Condition (M:N) + diagnosis_date, doctor_id
CREATE TABLE PatientCondition (
    patient_id     INTEGER NOT NULL,
    condition_id   INTEGER NOT NULL,
    diagnosis_date TEXT,            -- store ISO date string 'YYYY-MM-DD'
    doctor_id      INTEGER NOT NULL,
    PRIMARY KEY (patient_id, condition_id),
    FOREIGN KEY (patient_id)   REFERENCES Patient(patient_id),
    FOREIGN KEY (condition_id) REFERENCES "Condition"(condition_id),
    FOREIGN KEY (doctor_id)    REFERENCES Doctor(doctor_id)
);

-- Patient — Medication (M:N) + prescription_date, doctor_id
CREATE TABLE PatientMedication (
    patient_id        INTEGER NOT NULL,
    medication_id     INTEGER NOT NULL,
    prescription_date TEXT,
    doctor_id         INTEGER NOT NULL,
    PRIMARY KEY (patient_id, medication_id, prescription_date),
    FOREIGN KEY (patient_id)    REFERENCES Patient(patient_id),
    FOREIGN KEY (medication_id) REFERENCES Medication(medication_id),
    FOREIGN KEY (doctor_id)     REFERENCES Doctor(doctor_id)
);

-- Patient — Vaccine (M:N) + admin_date
CREATE TABLE PatientImmunization (
    patient_id INTEGER NOT NULL,
    vaccine_id INTEGER NOT NULL,
    admin_date TEXT,
    PRIMARY KEY (patient_id, vaccine_id, admin_date),
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (vaccine_id) REFERENCES Vaccine(vaccine_id)
);

-- Medication — Condition (M:N)
CREATE TABLE MedicationCondition (
    medication_id INTEGER NOT NULL,
    condition_id  INTEGER NOT NULL,
    PRIMARY KEY (medication_id, condition_id),
    FOREIGN KEY (medication_id) REFERENCES Medication(medication_id),
    FOREIGN KEY (condition_id)  REFERENCES "Condition"(condition_id)
);

------------------------------------------------
-- SAMPLE DATA
------------------------------------------------

-- Hospitals
INSERT INTO Hospital (hospital_id, name, city) VALUES
(1, 'Merced General Hospital', 'Merced'),
(2, 'Central Valley Medical Center', 'Fresno'),
(3, 'St. Catherine''s Clinic', 'Modesto');

-- Doctors
INSERT INTO Doctor (doctor_id, name, specialty, hospital_id, password) VALUES
(1, 'Dr. Alice Nguyen', 'Internal Medicine', 1, 'alice_pw'),
(2, 'Dr. Brian Lopez', 'Cardiology',       1, 'brian_pw'),
(3, 'Dr. Carla Singh', 'Endocrinology',    2, 'carla_pw'),
(4, 'Dr. David Kim',   'Pediatrics',       3, 'david_pw');


-- Patients
INSERT INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type) VALUES
(1, 'MRN-1001', 1985, 'Female', 'A+'),
(2, 'MRN-1002', 1992, 'Male',   'O-'),
(3, 'MRN-1003', 2004, 'Female', 'B+'),
(4, 'MRN-1004', 1978, 'Male',   'AB+'),
(5, 'MRN-1005', 1965, 'Female', 'O+');

-- Conditions
INSERT INTO "Condition" (condition_id, name) VALUES
(1, 'Hypertension'),
(2, 'Type 2 Diabetes'),
(3, 'Asthma'),
(4, 'Seasonal Allergies');

-- Medications
INSERT INTO Medication (medication_id, name) VALUES
(1, 'Lisinopril 10mg'),
(2, 'Metformin 500mg'),
(3, 'Albuterol Inhaler'),
(4, 'Cetirizine 10mg');

-- Vaccines
INSERT INTO Vaccine (vaccine_id, name) VALUES
(1, 'COVID-19 mRNA'),
(2, 'Influenza (Flu Shot)'),
(3, 'Tdap (Tetanus, Diphtheria, Pertussis)');

-- PatientDoctor
INSERT INTO PatientDoctor (patient_id, doctor_id) VALUES
(1, 1),
(1, 2),
(2, 1),
(3, 4),
(4, 2),
(5, 3);

-- PatientHospital
INSERT INTO PatientHospital (patient_id, hospital_id) VALUES
(1, 1),
(2, 1),
(3, 3),
(4, 1),
(4, 2),
(5, 2);

-- PatientCondition
INSERT INTO PatientCondition (patient_id, condition_id, diagnosis_date, doctor_id) VALUES
(1, 1, '2018-04-10', 1),
(1, 4, '2020-03-15', 1),
(2, 2, '2019-09-01', 3),
(3, 3, '2012-06-20', 4),
(4, 1, '2010-11-05', 2),
(5, 2, '2015-01-12', 3);

-- MedicationCondition
INSERT INTO MedicationCondition (medication_id, condition_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4);

-- PatientMedication
INSERT INTO PatientMedication (patient_id, medication_id, prescription_date, doctor_id) VALUES
(1, 1, '2023-01-10', 1),
(1, 4, '2023-03-22', 1),
(2, 2, '2022-10-05', 3),
(3, 3, '2024-02-01', 4),
(4, 1, '2021-08-15', 2),
(5, 2, '2020-05-30', 3);

-- PatientImmunization
INSERT INTO PatientImmunization (patient_id, vaccine_id, admin_date) VALUES
(1, 1, '2021-01-15'),
(1, 2, '2023-10-01'),
(2, 1, '2021-02-20'),
(2, 3, '2019-07-10'),
(3, 2, '2023-09-25'),
(4, 1, '2021-03-05'),
(5, 3, '2018-11-30');
