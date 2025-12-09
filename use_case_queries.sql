PRAGMA foreign_keys = ON;

------------------------------------------------------------
-- USE CASE 1: AUTHENTICATE USER (Doctor login)
------------------------------------------------------------

-- 1) Check if a doctor with given ID + name exists (login check)
SELECT doctor_id, name
FROM Doctor
WHERE doctor_id = 1
  AND name = 'Dr. Alice Nguyen';

-- 2) After "login", show doctor profile
SELECT doctor_id, name, specialty, hospital_id
FROM Doctor
WHERE doctor_id = 1;

-- 3) After "login", list all patients treated by that doctor
SELECT p.patient_id, p.medical_record_number
FROM Patient p
JOIN PatientDoctor pd ON p.patient_id = pd.patient_id
WHERE pd.doctor_id = 1;



------------------------------------------------------------
-- USE CASE 2: PATIENT LOOKUP / VIEW PATIENT DETAILS
------------------------------------------------------------

-- 4) Look up a patient using MRN
SELECT *
FROM Patient
WHERE medical_record_number = 'MRN-1001';

-- 5) Show patient demographics + hospitals (lookup by MRN)
SELECT p.patient_id,
       p.medical_record_number,
       p.birth_year,
       p.gender,
       p.blood_type,
       h.name  AS hospital_name,
       h.city  AS hospital_city
FROM Patient p
JOIN PatientHospital ph ON p.patient_id = ph.patient_id
JOIN Hospital h        ON ph.hospital_id = h.hospital_id
WHERE p.medical_record_number = 'MRN-1001';

-- 6) Show patient’s conditions, medications, and vaccines (summary)
SELECT p.patient_id,
       c.name AS condition_name,
       m.name AS medication_name,
       v.name AS vaccine_name
FROM Patient p
LEFT JOIN PatientCondition pc      ON p.patient_id = pc.patient_id
LEFT JOIN "Condition" c            ON pc.condition_id = c.condition_id
LEFT JOIN PatientMedication pm     ON p.patient_id = pm.patient_id
LEFT JOIN Medication m             ON pm.medication_id = m.medication_id
LEFT JOIN PatientImmunization pi   ON p.patient_id = pi.patient_id
LEFT JOIN Vaccine v                ON pi.vaccine_id = v.vaccine_id
WHERE p.patient_id = 1;



------------------------------------------------------------
-- USE CASE 3: ADD PATIENT
------------------------------------------------------------

-- 7) Insert a new patient record
INSERT INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type)
VALUES (300, 'MRN-3000', 2002, 'Male', 'B+');

-- 8) Assign the new patient to a hospital
INSERT INTO PatientHospital (patient_id, hospital_id)
VALUES (300, 1);  -- assumes hospital_id 1 exists

-- 9) Assign the new patient to a primary doctor
INSERT INTO PatientDoctor (patient_id, doctor_id)
VALUES (300, 1);  -- assumes doctor_id 1 exists

-- 10) Give the new patient a condition
INSERT INTO PatientCondition (patient_id, condition_id, diagnosis_date, doctor_id)
VALUES (300, 1, '2024-11-20', 1);  -- assumes condition_id 1 exists (Hypertension);



------------------------------------------------------------
-- USE CASE 4: UPDATE PATIENT
------------------------------------------------------------

-- 11) Update patient basic info (blood type)
UPDATE Patient
SET blood_type = 'A-'
WHERE patient_id = 3;

-- 12) Update patient’s birth year (correction)
UPDATE Patient
SET birth_year = 2005
WHERE patient_id = 3;



------------------------------------------------------------
-- USE CASE 5: DELETE PATIENT
------------------------------------------------------------

-- 13) Remove patient 300 associations with doctors (cleanup before delete)
DELETE FROM PatientDoctor
WHERE patient_id = 300;

-- 14) Remove patient 300 hospital links
DELETE FROM PatientHospital
WHERE patient_id = 300;

-- 15) Delete the actual patient record (outdated/invalid)
DELETE FROM Patient
WHERE patient_id = 300;



------------------------------------------------------------
-- USE CASE 6: BROWSE PATIENT TABLES
------------------------------------------------------------

-- 16) Browse all patients (raw list)
SELECT *
FROM Patient;

-- 17) Browse all conditions with how many patients have each one
SELECT c.name        AS condition_name,
       COUNT(pc.patient_id) AS num_patients
FROM "Condition" c
LEFT JOIN PatientCondition pc ON c.condition_id = pc.condition_id
GROUP BY c.condition_id, c.name
ORDER BY num_patients DESC;

-- 18) Browse all hospitals with their doctors
SELECT h.name AS hospital_name,
       d.name AS doctor_name,
       d.specialty
FROM Hospital h
JOIN Doctor d ON h.hospital_id = d.hospital_id
ORDER BY h.name, d.name;

-- 19) Browse patients and all medications they are taking
SELECT p.patient_id,
       p.medical_record_number,
       m.name AS medication_name,
       pm.prescription_date
FROM Patient p
JOIN PatientMedication pm ON p.patient_id = pm.patient_id
JOIN Medication m         ON pm.medication_id = m.medication_id
ORDER BY p.patient_id, pm.prescription_date;



------------------------------------------------------------
-- USE CASE 7: ANALYZE DISEASE / DEMOGRAPHIC PREVALENCE
------------------------------------------------------------

-- 20) Count patients by gender (overall demographic breakdown)
SELECT gender,
       COUNT(*) AS total_patients
FROM Patient
GROUP BY gender;

-- 21) Most prevalent gender for a specific condition (e.g., Hypertension)
SELECT c.name AS condition_name,
       p.gender,
       COUNT(*) AS total
FROM Patient p
JOIN PatientCondition pc ON p.patient_id = pc.patient_id
JOIN "Condition" c       ON pc.condition_id = c.condition_id
WHERE c.name = 'Hypertension'
GROUP BY c.name, p.gender
ORDER BY total DESC;

-- 22) Blood type distribution per condition
--     (use this to see which blood type is most common for each condition)
SELECT c.name      AS condition_name,
       p.blood_type,
       COUNT(*)    AS num_patients
FROM Patient p
JOIN PatientCondition pc ON p.patient_id = pc.patient_id
JOIN "Condition" c       ON pc.condition_id = c.condition_id
GROUP BY c.name, p.blood_type
ORDER BY c.name, num_patients DESC;

-- 23) Number of patients that took each vaccine
SELECT v.name AS vaccine_name,
       COUNT(DISTINCT pi.patient_id) AS num_patients_vaccinated
FROM Vaccine v
LEFT JOIN PatientImmunization pi ON v.vaccine_id = pi.vaccine_id
GROUP BY v.vaccine_id, v.name
ORDER BY num_patients_vaccinated DESC;

-- 24) For each condition, how many distinct patients exist per gender
--     (richer view of disease prevalence by gender)
SELECT c.name   AS condition_name,
       p.gender,
       COUNT(DISTINCT p.patient_id) AS num_patients
FROM Patient p
JOIN PatientCondition pc ON p.patient_id = pc.patient_id
JOIN "Condition" c       ON pc.condition_id = c.condition_id
GROUP BY c.name, p.gender
ORDER BY c.name, num_patients DESC;
