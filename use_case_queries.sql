PRAGMA foreign_keys = ON;

------------------------------------------------
-- 1) List all patients born after 1990
------------------------------------------------
SELECT patient_id, medical_record_number, birth_year, gender, blood_type
FROM Patient
WHERE birth_year > 1990;

------------------------------------------------
-- 2) List all doctors and the hospital they work at
------------------------------------------------
SELECT d.doctor_id, d.name AS doctor_name, d.specialty, h.name AS hospital_name
FROM Doctor d
JOIN Hospital h ON d.hospital_id = h.hospital_id;

------------------------------------------------
-- 3) List each patient with all their doctors
------------------------------------------------
SELECT p.patient_id, p.medical_record_number, d.name AS doctor_name
FROM Patient p
JOIN PatientDoctor pd ON p.patient_id = pd.patient_id
JOIN Doctor d ON pd.doctor_id = d.doctor_id
ORDER BY p.patient_id, d.doctor_id;

------------------------------------------------
-- 4) List medications used to treat each condition
------------------------------------------------
SELECT c.name AS condition_name, m.name AS medication_name
FROM "Condition" c
JOIN MedicationCondition mc ON c.condition_id = mc.condition_id
JOIN Medication m ON mc.medication_id = m.medication_id
ORDER BY c.name, m.name;

------------------------------------------------
-- 5) Count how many conditions each patient has
------------------------------------------------
SELECT p.patient_id,
       p.medical_record_number,
       COUNT(pc.condition_id) AS num_conditions
FROM Patient p
LEFT JOIN PatientCondition pc ON p.patient_id = pc.patient_id
GROUP BY p.patient_id, p.medical_record_number
ORDER BY num_conditions DESC;

------------------------------------------------
-- 6) Number of patients per hospital
------------------------------------------------
SELECT h.name AS hospital_name,
       COUNT(ph.patient_id) AS num_patients
FROM Hospital h
LEFT JOIN PatientHospital ph ON h.hospital_id = ph.hospital_id
GROUP BY h.hospital_id, h.name
ORDER BY num_patients DESC;

------------------------------------------------
-- 7) Patients who currently have more than one doctor
------------------------------------------------
SELECT p.patient_id, p.medical_record_number, COUNT(pd.doctor_id) AS doctor_count
FROM Patient p
JOIN PatientDoctor pd ON p.patient_id = pd.patient_id
GROUP BY p.patient_id, p.medical_record_number
HAVING COUNT(pd.doctor_id) > 1;

------------------------------------------------
-- 8) Patients with no recorded medications
------------------------------------------------
SELECT p.patient_id, p.medical_record_number
FROM Patient p
LEFT JOIN PatientMedication pm ON p.patient_id = pm.patient_id
WHERE pm.patient_id IS NULL;

------------------------------------------------
-- 9) List all vaccines each patient has received
------------------------------------------------
SELECT p.patient_id,
       p.medical_record_number,
       v.name AS vaccine_name,
       pi.admin_date
FROM Patient p
JOIN PatientImmunization pi ON p.patient_id = pi.patient_id
JOIN Vaccine v ON pi.vaccine_id = v.vaccine_id
ORDER BY p.patient_id, pi.admin_date;

------------------------------------------------
-- 10) Patients who have taken a medication used for Hypertension
------------------------------------------------
SELECT DISTINCT p.patient_id, p.medical_record_number
FROM Patient p
JOIN PatientMedication pm ON p.patient_id = pm.patient_id
WHERE pm.medication_id IN (
    SELECT mc.medication_id
    FROM MedicationCondition mc
    JOIN "Condition" c ON mc.condition_id = c.condition_id
    WHERE c.name = 'Hypertension'
);

------------------------------------------------
-- 11) Total number of vaccinations per vaccine type
------------------------------------------------
SELECT v.name AS vaccine_name,
       COUNT(*) AS num_doses
FROM Vaccine v
LEFT JOIN PatientImmunization pi ON v.vaccine_id = pi.vaccine_id
GROUP BY v.vaccine_id, v.name
ORDER BY num_doses DESC;

------------------------------------------------
-- 12) INSERT: add a new patient
------------------------------------------------
INSERT INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type)
VALUES (100, 'MRN-1100', 2003, 'Female', 'A+');

------------------------------------------------
-- 13) INSERT: assign the new patient to an existing hospital
------------------------------------------------
INSERT INTO PatientHospital (patient_id, hospital_id)
VALUES (100, 1);  -- assumes hospital_id 1 exists

------------------------------------------------
-- 14) INSERT: assign the new patient to an existing doctor
------------------------------------------------
INSERT INTO PatientDoctor (patient_id, doctor_id)
VALUES (100, 1);  -- assumes doctor_id 1 exists

------------------------------------------------
-- 15) INSERT: give the new patient a condition and diagnosis info
------------------------------------------------
INSERT INTO PatientCondition (patient_id, condition_id, diagnosis_date, doctor_id)
VALUES (100, 1, '2024-10-01', 1);  -- assumes condition_id 1 and doctor_id 1 exist

------------------------------------------------
-- 16) UPDATE: correct the new patient’s blood type
------------------------------------------------
UPDATE Patient
SET blood_type = 'O+'
WHERE patient_id = 100;

------------------------------------------------
-- 17) UPDATE: move a doctor to a different hospital
------------------------------------------------
UPDATE Doctor
SET hospital_id = 2
WHERE doctor_id = 1;  -- assumes hospital_id 2 exists

------------------------------------------------
-- 18) UPDATE: change diagnosis date for a specific patient-condition pair
------------------------------------------------
UPDATE PatientCondition
SET diagnosis_date = '2024-11-15'
WHERE patient_id = 100 AND condition_id = 1;

------------------------------------------------
-- 19) DELETE: remove one vaccination record for a patient (if it exists)
------------------------------------------------
DELETE FROM PatientImmunization
WHERE patient_id = 1 AND vaccine_id = 2;

------------------------------------------------
-- 20) DELETE: remove a doctor–patient relationship (not the doctor or patient)
------------------------------------------------
DELETE FROM PatientDoctor
WHERE patient_id = 100 AND doctor_id = 1;
