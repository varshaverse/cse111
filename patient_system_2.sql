-- 1. Get all patients
SELECT * FROM Patient;

-- 2. Get all doctors specializing in cardiology
SELECT name 
FROM Doctor 
WHERE specialty = 'Cardiology';

-- 3. List all patients treated at each hospital
SELECT p.patient_id, h.name AS hospital
FROM Patient p
JOIN PatientHospital ph ON p.patient_id = ph.patient_id
JOIN Hospital h ON ph.hospital_id = h.hospital_id;

-- 4. Count how many patients each doctor has
SELECT d.name, COUNT(*) AS patient_count
FROM Doctor d
JOIN PatientDoctor pd ON d.doctor_id = pd.doctor_id
GROUP BY d.doctor_id;

-- 5. Find patients with more than 1 condition
SELECT patient_id
FROM PatientCondition
GROUP BY patient_id
HAVING COUNT(*) > 1;

-- 6. List all medications prescribed to patient 201
SELECT m.name
FROM PatientMedication pm
JOIN Medication m ON pm.medication_id = m.medication_id
WHERE pm.patient_id = 201;

-- 7. Find all female patients treated by doctor 101
SELECT p.patient_id, p.gender
FROM PatientDoctor pd
JOIN Patient p ON pd.patient_id = p.patient_id
WHERE pd.doctor_id = 101 AND p.gender = 'F';

-- 8. List all conditions diagnosed for patient 201
SELECT c.name, pc.diagnosis_date
FROM PatientCondition pc
JOIN Condition c ON pc.condition_id = c.condition_id
WHERE pc.patient_id = 201;

-- 9. Count patients by blood type
SELECT blood_type, COUNT(*) AS total
FROM Patient
GROUP BY blood_type;

-- 10. Find hospitals with more than 1 patient visit
SELECT hospital_id, COUNT(*) AS visit_count
FROM PatientHospital
GROUP BY hospital_id
HAVING COUNT(*) > 1;


-- =====================================================
-- INSERT STATEMENTS
-- =====================================================

-- 11. Insert a new patient
INSERT INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type)
VALUES (300, 'MR300', 1995, 'M', 'B+');

-- 12. Insert a new doctor
INSERT INTO Doctor (doctor_id, name, specialty, hospital_id)
VALUES (150, 'Dr. Jane Lee', 'Dermatology', 1);

-- 13. Insert a new hospital visit
INSERT INTO PatientHospital (patient_id, hospital_id)
VALUES (300, 1);

-- 14. Insert a new diagnosis for a patient
INSERT INTO PatientCondition (patient_id, condition_id, diagnosis_date, diagnosed_by_doctor_id)
VALUES (300, 301, '2024-02-15', 150);


-- =====================================================
-- UPDATE STATEMENTS
-- =====================================================

-- 15. Update a patient's birth year
UPDATE Patient
SET birth_year = 1996
WHERE patient_id = 300;

-- 16. Change a doctor's specialty
UPDATE Doctor
SET specialty = 'General Medicine'
WHERE doctor_id = 150;

-- 17. Update a medication name
UPDATE Medication
SET name = 'Amlodipine 20mg'
WHERE medication_id = 401;


-- =====================================================
-- DELETE STATEMENTS
-- =====================================================

-- 18. Remove a patient's hospital visit
DELETE FROM PatientHospital
WHERE patient_id = 300 AND hospital_id = 1;

-- 19. Delete a diagnosis record
DELETE FROM PatientCondition
WHERE patient_id = 300 AND condition_id = 301;

-- 20. Delete a doctor with no patients
DELETE FROM Doctor
WHERE doctor_id = 150;
