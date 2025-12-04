PRAGMA foreign_keys = ON;

---------------------------------------
-- MORE BASE ENTITIES
---------------------------------------

-- More hospitals
INSERT INTO Hospital (hospital_id, name, city) VALUES
(4, 'North Valley Rehab Center', 'Merced');

-- Additional doctors with passwords
INSERT INTO Doctor (doctor_id, name, specialty, hospital_id, password) VALUES
(5, 'Dr. Elena Cruz', 'Family Medicine', 4, 'elena_pw'),
(6, 'Dr. Jorge Ramirez', 'Pulmonology', 2, 'jorge_pw');


-- More patients
INSERT INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type) VALUES
(6, 'MRN-1006', 2001, 'Male',   'A-'),
(7, 'MRN-1007', 1999, 'Female', 'B-'),
(8, 'MRN-1008', 1970, 'Male',   'O+');

-- More conditions
INSERT INTO "Condition" (condition_id, name) VALUES
(5, 'Obesity'),
(6, 'Chronic Obstructive Pulmonary Disease');

-- More medications
INSERT INTO Medication (medication_id, name) VALUES
(5, 'Atorvastatin 20mg'),
(6, 'Insulin Glargine');

-- More vaccines
INSERT INTO Vaccine (vaccine_id, name) VALUES
(4, 'Pneumococcal'),
(5, 'HPV');


---------------------------------------
-- MANY-TO-MANY: Patient ↔ Doctor
---------------------------------------
-- Show: patients with multiple doctors AND doctors with multiple patients

INSERT INTO PatientDoctor (patient_id, doctor_id) VALUES
(2, 3),  -- patient 2 also sees Dr. Carla
(2, 5),  -- and Dr. Cruz
(3, 1),  -- patient 3 also sees Dr. Alice
(5, 5),  -- patient 5 sees Dr. Cruz
(6, 1),  -- new patient 6 sees Dr. Alice
(6, 3),  -- and Dr. Carla -> many doctors
(7, 5),  -- patient 7 sees Dr. Cruz
(8, 2),  -- patient 8 sees Dr. Brian
(8, 6);  -- and Dr. Ramirez


---------------------------------------
-- MANY-TO-MANY: Patient ↔ Hospital
---------------------------------------
-- Show: patients visiting multiple hospitals and hospitals having many patients

INSERT INTO PatientHospital (patient_id, hospital_id) VALUES
(1, 2),  -- patient 1 now also uses hospital 2
(2, 2),  -- patient 2 also at hospital 2
(3, 1),  -- patient 3 also at hospital 1
(5, 3),  -- patient 5 also at hospital 3
(6, 4),  -- patient 6 at hospital 4
(7, 2),  -- patient 7 at hospital 2
(8, 4);  -- patient 8 at hospital 4


---------------------------------------
-- MANY-TO-MANY: Patient ↔ Condition
---------------------------------------
-- Each patient can have many conditions, each condition appears on many patients

INSERT INTO PatientCondition (patient_id, condition_id, diagnosis_date, doctor_id) VALUES
(1, 2, '2023-06-01', 1),  -- patient 1 also has diabetes
(2, 1, '2021-02-11', 3),  -- patient 2 also has hypertension
(2, 5, '2022-08-19', 3),  -- patient 2 has obesity
(3, 4, '2020-09-09', 4),  -- patient 3 also has allergies
(6, 1, '2022-01-15', 5),  -- new patient 6: hypertension
(6, 5, '2023-04-25', 5),  -- and obesity
(7, 2, '2020-11-30', 3),  -- patient 7: diabetes
(7, 6, '2024-02-14', 6),  -- and COPD
(8, 6, '2018-05-20', 6);  -- patient 8: COPD


---------------------------------------
-- MANY-TO-MANY: Medication ↔ Condition
---------------------------------------
-- One med can treat many conditions, one condition can have many meds

INSERT INTO MedicationCondition (medication_id, condition_id) VALUES
(5, 1),  -- Atorvastatin also used for hypertensive patients (risk factors)
(5, 5),  -- Atorvastatin for obesity-related dyslipidemia
(2, 5),  -- Metformin sometimes used in obesity/insulin resistance
(6, 2),  -- Insulin Glargine for diabetes
(6, 5);  -- Insulin also in obese diabetics


---------------------------------------
-- MANY-TO-MANY: Patient ↔ Medication
---------------------------------------
-- Multiple meds per patient and same med used by many patients

INSERT INTO PatientMedication (patient_id, medication_id, prescription_date, doctor_id) VALUES
(1, 5, '2024-01-05', 1),  -- patient 1 also gets Atorvastatin
(2, 6, '2023-03-18', 3),  -- patient 2 gets insulin
(2, 2, '2023-09-10', 3),  -- second Metformin prescription (later date)
(3, 4, '2023-11-11', 4),  -- patient 3 gets Cetirizine
(4, 5, '2022-12-01', 2),  -- patient 4 gets Atorvastatin
(5, 1, '2019-07-22', 2),  -- patient 5 gets Lisinopril
(6, 2, '2024-04-01', 5),  -- patient 6 on Metformin
(6, 5, '2024-09-09', 5),  -- and Atorvastatin
(7, 6, '2023-06-06', 3),  -- patient 7 on insulin
(8, 1, '2020-02-02', 2);  -- patient 8 on Lisinopril


---------------------------------------
-- MANY-TO-MANY: Patient ↔ Vaccine
---------------------------------------
-- Multiple vaccines per patient, same vaccine across many patients

INSERT INTO PatientImmunization (patient_id, vaccine_id, admin_date) VALUES
(3, 1, '2021-12-15'),  -- patient 3 gets COVID
(3, 3, '2022-01-20'),  -- and Tdap
(4, 2, '2022-10-10'),  -- patient 4 gets flu shot
(5, 1, '2019-01-01'),  -- patient 5 gets COVID (pretend early trial lol)
(6, 1, '2022-03-03'),  -- patient 6 COVID
(6, 4, '2023-08-08'),  -- patient 6 Pneumococcal
(7, 2, '2020-09-09'),  -- patient 7 Flu
(7, 5, '2021-05-05'),  -- patient 7 HPV
(8, 3, '2017-07-07'),  -- patient 8 Tdap
(8, 4, '2018-08-08');  -- patient 8 Pneumococcal
