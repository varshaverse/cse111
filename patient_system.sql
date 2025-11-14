-- ======================================================
-- PATIENT RECORDS & ANALYTICS SYSTEM FOR DOCTORS
-- This script is safe to run multiple times in SQLite.
-- ======================================================

-- 1. CREATE TABLE Hospital
CREATE TABLE IF NOT EXISTS Hospital (
    hospital_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100)
);

-- 2. CREATE TABLE Doctor
CREATE TABLE IF NOT EXISTS Doctor (
    doctor_id INT PRIMARY KEY,
    name VARCHAR(100),
    specialty VARCHAR(100),
    hospital_id INT,
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id)
);

-- 3. CREATE TABLE Patient
CREATE TABLE IF NOT EXISTS Patient (
    patient_id INT PRIMARY KEY,
    medical_record_number VARCHAR(50),
    birth_year INT,
    gender CHAR(1),
    blood_type VARCHAR(3)
);

-- 4. CREATE TABLE Condition
CREATE TABLE IF NOT EXISTS Condition (
    condition_id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- 5. CREATE TABLE Medication
CREATE TABLE IF NOT EXISTS Medication (
    medication_id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- 6. CREATE TABLE Vaccine
CREATE TABLE IF NOT EXISTS Vaccine (
    vaccine_id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- 7. CREATE TABLE PatientDoctor (Many-to-Many: Patient to Doctor)
CREATE TABLE IF NOT EXISTS PatientDoctor (
    patient_id INT,
    doctor_id INT,
    PRIMARY KEY (patient_id, doctor_id),
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctor(doctor_id)
);

-- 8. CREATE TABLE PatientHospital (Patient visits history)
CREATE TABLE IF NOT EXISTS PatientHospital (
    patient_id INT,
    hospital_id INT,
    PRIMARY KEY (patient_id, hospital_id),
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id)
);

-- 9. CREATE TABLE PatientCondition
CREATE TABLE IF NOT EXISTS PatientCondition (
    patient_id INT,
    condition_id INT,
    diagnosis_date DATE,
    diagnosed_by_doctor_id INT,
    PRIMARY KEY (patient_id, condition_id, diagnosis_date),
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (condition_id) REFERENCES Condition(condition_id),
    FOREIGN KEY (diagnosed_by_doctor_id) REFERENCES Doctor(doctor_id)
);

-- 10. CREATE TABLE PatientMedication
CREATE TABLE IF NOT EXISTS PatientMedication (
    patient_id INT,
    medication_id INT,
    prescription_date DATE,
    prescribed_by_doctor_id INT,
    PRIMARY KEY (patient_id, medication_id, prescription_date),
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (medication_id) REFERENCES Medication(medication_id),
    FOREIGN KEY (prescribed_by_doctor_id) REFERENCES Doctor(doctor_id)
);

-- 11. CREATE TABLE PatientImmunization
CREATE TABLE IF NOT EXISTS PatientImmunization (
    patient_id INT,
    vaccine_id INT,
    admin_date DATE,
    PRIMARY KEY (patient_id, vaccine_id, admin_date),
    FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    FOREIGN KEY (vaccine_id) REFERENCES Vaccine(vaccine_id)
);

-- ======================================================
-- INSERT SAMPLE DATA (Using OR IGNORE to prevent duplicates)
-- ======================================================

-- 12. Insert Hospitals
INSERT OR IGNORE INTO Hospital (hospital_id, name, city) VALUES (1, 'Sutter Health Medical Hospital', 'California');
INSERT OR IGNORE INTO Hospital (hospital_id, name, city) VALUES (2, 'Lakeside Medical Center', 'Chicago');

-- 13. Insert Doctors
INSERT OR IGNORE INTO Doctor (doctor_id, name, specialty, hospital_id) VALUES (101, 'Dr. Alice Kim', 'Cardiology', 1);
INSERT OR IGNORE INTO Doctor (doctor_id, name, specialty, hospital_id) VALUES (102, 'Dr. Bob Smith', 'Neurology', 2);

-- 14. Insert Patients
INSERT OR IGNORE INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type) VALUES (201, 'MR001', 1985, 'F', 'A+');
INSERT OR IGNORE INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type) VALUES (202, 'MR002', 1970, 'M', 'O-');

-- 15. Insert Conditions, Medications, Vaccines
INSERT OR IGNORE INTO Condition (condition_id, name) VALUES (301, 'Hypertension');
INSERT OR IGNORE INTO Medication (medication_id, name) VALUES (401, 'Amlodipine');
INSERT OR IGNORE INTO Vaccine (vaccine_id, name) VALUES (501, 'Influenza');

-- 16. Link Patients to Doctors/Hospitals
INSERT OR IGNORE INTO PatientDoctor (patient_id, doctor_id) VALUES (201, 101);
INSERT OR IGNORE INTO PatientHospital (patient_id, hospital_id) VALUES (201, 1);
INSERT OR IGNORE INTO PatientHospital (patient_id, hospital_id) VALUES (202, 2);

-- 17. Add Condition to a Patient
INSERT OR IGNORE INTO PatientCondition (patient_id, condition_id, diagnosis_date, diagnosed_by_doctor_id) VALUES (201, 301, '2023-01-05', 101);

-- 18. Add Medication Record
INSERT OR IGNORE INTO PatientMedication (patient_id, medication_id, prescription_date, prescribed_by_doctor_id) VALUES (201, 401, '2023-01-10', 101);

-- 19. Add Immunization Record
INSERT OR IGNORE INTO PatientImmunization (patient_id, vaccine_id, admin_date) VALUES (201, 501, '2023-02-01');

-- ======================================================
-- UPDATE / DELETE OPERATIONS
-- Updates do not cause UNIQUE constraint errors, so no OR IGNORE is needed.
-- ======================================================

-- 20. Update patient birth year
UPDATE Patient
SET birth_year = 1986
WHERE patient_id = 201;