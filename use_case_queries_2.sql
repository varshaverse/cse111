-- Q1: Authenticate User
-- Use case: Authenticate User (Doctor login)
-- Tables involved: 1 (Doctor)
-- Description: Check if a doctor with given ID and name exists and output all basic info on the doctor. 
-- (in this case the doctor name does not exist in the records)
-- Doctor id 1's actual name is Dr. Alice Nguyen
-- correct: SELECT * FROM Doctor WHERE doctor_id = 1 AND name = 'Dr. Alice Nguyen';
SELECT * FROM Doctor 
WHERE doctor_id = 1 AND name = 'Alice Carter';

-- Q2: Browse Patient Table
-- Use case: Browse patient tables
-- Tables involved: 1 (Patient)
-- Description: List basic patient information.
SELECT patient_id, medical_record_number, gender, birth_year, blood_type
FROM Patient;

-- Q3: View Full Patient Details
-- Use case: View Patient Details (extends Patient Lookup by ID)
-- Tables involved: 5 (Patient, PatientCondition, Condition, PatientMedication, Medication)
-- Description: Show a patient's demographics, conditions, and medications.
SELECT p.*, 
       c.name AS condition_name, 
       m.name AS medication_name
FROM Patient p
LEFT JOIN PatientCondition pc ON p.patient_id = pc.patient_id
LEFT JOIN Condition c        ON pc.condition_id = c.condition_id
LEFT JOIN PatientMedication pm ON p.patient_id = pm.patient_id
LEFT JOIN Medication m       ON pm.medication_id = m.medication_id
WHERE p.patient_id = 1;

-- Q4: Patient Lookup by MRN
-- Use case: Patient Lookup by MRN
-- Tables involved: 1 (Patient)
-- Description: Retrieve one patient record by primary key.
SELECT *
FROM Patient
WHERE medical_record_number = 'MRN-1002';

-- Q5: Add Patient
-- Use case: Add Patient
-- Tables involved: 1 (Patient)
-- Description: Insert a new patient record.
INSERT INTO Patient (patient_id, medical_record_number, birth_year, gender, blood_type)
VALUES (9, 'MRN-1009', 1999, 'Female', 'AB+');

-- Q6: Update Patient Details
-- Use case: Update Patient Details
-- Tables involved: 1 (Patient)
-- Description: Update a patient's blood type.
UPDATE Patient
SET blood_type = 'O-'
WHERE patient_id = 2;

-- Q7: Delete Patient
-- Use case: Delete Patient
-- Tables involved: 1 (Patient)
-- Description: Remove a patient record.
DELETE FROM Patient
WHERE patient_id = 10;

-- Q8: List Doctors Treating a Specific Patient
-- Use case: View Patient Details / Doctor-Patient mapping
-- Tables involved: 2 (Doctor, PatientDoctor)
-- Description: Show names and specialties of doctors treating patient 1.
SELECT d.name, d.specialty
FROM Doctor d
JOIN PatientDoctor pd ON d.doctor_id = pd.doctor_id
WHERE pd.patient_id = 1;

-- Q9: Patients With a Specific Condition
-- Use case: Run Analytics – condition-based patient list
-- Tables involved: 2 (Patient, PatientCondition)
-- Description: All patients diagnosed with condition 1.
SELECT p.patient_id, p.gender, p.birth_year
FROM Patient p
JOIN PatientCondition pc ON p.patient_id = pc.patient_id
WHERE pc.condition_id = 1;

-- Q10: Medications Used to Treat a Condition
-- Use case: Run Analytics – medication vs condition
-- Tables involved: 2 (Medication, MedicationCondition)
-- Description: Get all medications that treat condition 3.
SELECT m.name
FROM Medication m
JOIN MedicationCondition mc ON m.medication_id = mc.medication_id
WHERE mc.condition_id = 3;

-- Q11: Vaccines a Patient Has Received
-- Use case: View Patient Details – immunization history
-- Tables involved: 3 (Vaccine, PatientImmunization, Patient)
-- Description: List vaccines and administration dates for patient 1.
SELECT v.name, pi.admin_date
FROM Vaccine v
JOIN PatientImmunization pi ON v.vaccine_id = pi.vaccine_id
JOIN Patient p ON pi.patient_id = p.patient_id
WHERE p.patient_id = 1;

-- Q12: Hospital Where a Doctor Works
-- Use case: Run Analytics / doctor-hospital info
-- Tables involved: 2 (Doctor, Hospital)
-- Description: Show the hospital for doctor 1.
SELECT h.name, h.city
FROM Hospital h
JOIN Doctor d ON h.hospital_id = d.hospital_id
WHERE d.doctor_id = 1;

-- Q13: Patients Visiting a Specific Hospital
-- Use case: Run Analytics – hospital census
-- Tables involved: 3 (Patient, PatientHospital, Hospital)
-- Description: List patients associated with hospital 1.
SELECT p.patient_id, p.gender, p.birth_year
FROM Patient p
JOIN PatientHospital ph ON p.patient_id = ph.patient_id
JOIN Hospital h        ON ph.hospital_id = h.hospital_id
WHERE h.hospital_id = 1;

-- Q14: Count Conditions Per Patient
-- Use case: Run Analytics – patient complexity
-- Tables involved: 1 (PatientCondition)
-- Description: Count how many conditions patient 1 has.
SELECT COUNT(*) AS num_conditions
FROM PatientCondition
WHERE patient_id = 1;

-- Q15: Number of Patients Per Doctor
-- Use case: Run Analytics – doctor workload
-- Tables involved: 2 (Doctor, PatientDoctor)
-- Description: Show each doctor and how many distinct patients they treat.
SELECT d.name,
       COUNT(DISTINCT pd.patient_id) AS num_patients
FROM Doctor d
LEFT JOIN PatientDoctor pd ON d.doctor_id = pd.doctor_id
GROUP BY d.name;

-- Q16: Patients With More Than One Medication
-- Use case: Run Analytics – polypharmacy detection
-- Tables involved: 1 (PatientMedication)
-- Description: Find patients who are on more than one medication.
SELECT patient_id
FROM PatientMedication
GROUP BY patient_id
HAVING COUNT(medication_id) > 1;

-- Q17: Patient, Condition, and Medication That Treats the Condition
-- Use case: Run Analytics – condition-treatment mapping per patient
-- Tables involved: 5 (Patient, PatientCondition, Condition, MedicationCondition, Medication)
-- Description: For each patient-condition pair, list medications indicated for that condition.
SELECT p.patient_id,
       c.name AS condition_name,
       m.name AS medication_name
FROM Patient p
JOIN PatientCondition pc   ON p.patient_id = pc.patient_id
JOIN Condition c           ON pc.condition_id = c.condition_id
JOIN MedicationCondition mc ON c.condition_id = mc.condition_id
JOIN Medication m          ON mc.medication_id = m.medication_id;

-- Q18: Patients Treated by Doctors With a Specific Specialty
-- Use case: Run Analytics – specialty-based patient list
-- Tables involved: 3 (Patient, PatientDoctor, Doctor)
-- Description: Patients treated by cardiologists.
SELECT DISTINCT p.*
FROM Patient p
JOIN PatientDoctor pd ON p.patient_id = pd.patient_id
JOIN Doctor d         ON pd.doctor_id = d.doctor_id
WHERE d.specialty = 'Cardiology';

-- Q19: Doctors Who Prescribed Medication to a Patient
-- Use case: View Patient Details – prescribing doctors
-- Tables involved: 3 (Doctor, PatientMedication, Patient)
-- Description: Distinct doctors who prescribed any medication to patient 1.
SELECT DISTINCT d.name
FROM Doctor d
JOIN PatientMedication pm ON d.doctor_id = pm.doctor_id
JOIN Patient p           ON pm.patient_id = p.patient_id
WHERE p.patient_id = 1;

-- Q20: Hospitals Where a Patient's Doctors Work
-- Use case: Run Analytics – care network for a patient
-- Tables involved: 4 (Hospital, Doctor, PatientDoctor, Patient)
-- Description: List hospitals associated with doctors who treat patient 1.
SELECT DISTINCT h.name
FROM Hospital h
JOIN Doctor d         ON h.hospital_id = d.hospital_id
JOIN PatientDoctor pd ON pd.doctor_id = d.doctor_id
JOIN Patient p        ON pd.patient_id = p.patient_id
WHERE p.patient_id = 1;

-- Q21: Patients, Their Hospitals, and Their Doctors
-- Use case: Run Analytics – full care context
-- Tables involved: 5 (Patient, PatientHospital, Hospital, PatientDoctor, Doctor)
-- Description: Show which hospitals and doctors are connected to each patient.
SELECT p.patient_id,
       p.medical_record_number,
       h.name AS hospital_name,
       d.name AS doctor_name,
       d.specialty
FROM Patient p
JOIN PatientHospital ph ON p.patient_id = ph.patient_id
JOIN Hospital h         ON ph.hospital_id = h.hospital_id
JOIN PatientDoctor pd   ON p.patient_id = pd.patient_id
JOIN Doctor d           ON pd.doctor_id = d.doctor_id
ORDER BY p.patient_id, h.name, d.name;

-- Q22: Number of Patients With Each Condition Per Hospital
-- Use case: Run Analytics – condition distribution per hospital
-- Tables involved: 4 (Hospital, PatientHospital, PatientCondition, Condition)
-- Description: For each hospital, count patients by condition.
SELECT h.name AS hospital_name,
       c.name AS condition_name,
       COUNT(DISTINCT pc.patient_id) AS num_patients
FROM Hospital h
JOIN PatientHospital ph ON h.hospital_id = ph.hospital_id
JOIN PatientCondition pc ON ph.patient_id = pc.patient_id
JOIN Condition c         ON pc.condition_id = c.condition_id
GROUP BY h.name, c.name
ORDER BY h.name, num_patients DESC;

-- Q23: Number of Distinct Conditions Diagnosed by Each Doctor
-- Use case: Run Analytics – doctor experience breadth
-- Tables involved: 3 (Doctor, PatientCondition, Condition)
-- Description: For each doctor, count distinct conditions they have diagnosed.
SELECT d.doctor_id,
       d.name,
       COUNT(DISTINCT pc.condition_id) AS num_conditions_diagnosed
FROM Doctor d
JOIN PatientCondition pc ON d.doctor_id = pc.doctor_id
JOIN Condition c         ON pc.condition_id = c.condition_id
GROUP BY d.doctor_id, d.name
ORDER BY num_conditions_diagnosed DESC;

-- Q24: Medications Prescribed for a Condition and Number of Patients on Each
-- Use case: Run Analytics – treatment popularity per condition
-- Tables involved: 5 (Condition, MedicationCondition, Medication, PatientMedication, PatientCondition)
-- Description: For each condition, show medications and patient counts using them.
SELECT c.name AS condition_name,
       m.name AS medication_name,
       COUNT(DISTINCT pm.patient_id) AS num_patients_on_med
FROM Condition c
JOIN MedicationCondition mc ON c.condition_id = mc.condition_id
JOIN Medication m           ON mc.medication_id = m.medication_id
JOIN PatientMedication pm   ON m.medication_id = pm.medication_id
JOIN PatientCondition pc    ON pm.patient_id = pc.patient_id
                           AND pc.condition_id = c.condition_id
GROUP BY c.name, m.name
ORDER BY c.name, num_patients_on_med DESC;

-- Q25: Patients With a Given Condition Who Received a Given Vaccine
-- Use case: Run Analytics – condition + vaccination combination
-- Tables involved: 5 (Patient, PatientCondition, Condition, PatientImmunization, Vaccine)
-- Description: Patients with Asthma who received the Influenza vaccine.
SELECT DISTINCT p.patient_id,
       p.medical_record_number,
       p.gender,
       p.birth_year
FROM Patient p
JOIN PatientCondition pc    ON p.patient_id = pc.patient_id
JOIN Condition c            ON pc.condition_id = c.condition_id
JOIN PatientImmunization pi ON p.patient_id = pi.patient_id
JOIN Vaccine v              ON pi.vaccine_id = v.vaccine_id
WHERE c.name = 'Asthma'
  AND v.name = 'Influenza';

-- Q26: Doctors Whose Patients Are Hospitalized in a Specific City
-- Use case: Run Analytics – regional doctor involvement
-- Tables involved: 4 (Doctor, PatientDoctor, PatientHospital, Hospital)
-- Description: Doctors who treat patients associated with hospitals in Los Angeles.
SELECT DISTINCT d.doctor_id,
       d.name,
       d.specialty,
       h.city
FROM Doctor d
JOIN PatientDoctor pd   ON d.doctor_id = pd.doctor_id
JOIN PatientHospital ph ON pd.patient_id = ph.patient_id
JOIN Hospital h         ON ph.hospital_id = h.hospital_id
WHERE h.city = 'Los Angeles';

-- Q27: Average Number of Medications Per Patient Per Hospital
-- Use case: Run Analytics – medication load by hospital
-- Tables involved: 4 (PatientHospital, PatientMedication, Hospital + derived subquery)
-- Description: Compute average medications per patient for each hospital.
SELECT h.name AS hospital_name,
       AVG(t.med_count) AS avg_meds_per_patient
FROM (
    SELECT ph.hospital_id,
           pm.patient_id,
           COUNT(pm.medication_id) AS med_count
    FROM PatientHospital ph
    JOIN PatientMedication pm ON ph.patient_id = pm.patient_id
    GROUP BY ph.hospital_id, pm.patient_id
) AS t
JOIN Hospital h ON t.hospital_id = h.hospital_id
GROUP BY h.name
ORDER BY avg_meds_per_patient DESC;

-- Q28: Patients Treated by Doctors From Multiple Hospitals
-- Use case: Run Analytics – cross-hospital care
-- Tables involved: 4 (Patient, PatientDoctor, Doctor, Hospital)
-- Description: Patients whose doctors work at more than one distinct hospital.
SELECT p.patient_id,
       p.medical_record_number,
       COUNT(DISTINCT d.hospital_id) AS num_hospitals_of_doctors
FROM Patient p
JOIN PatientDoctor pd ON p.patient_id = pd.patient_id
JOIN Doctor d         ON pd.doctor_id = d.doctor_id
JOIN Hospital h       ON d.hospital_id = h.hospital_id
GROUP BY p.patient_id, p.medical_record_number
HAVING COUNT(DISTINCT d.hospital_id) > 1;

-- Q29: For Each Vaccine, Count How Many Hospitals' Patients Received It
-- Use case: Run Analytics – vaccine reach by hospital
-- Tables involved: 4 (Vaccine, PatientImmunization, PatientHospital, Hospital)
-- Description: For each vaccine, count distinct hospitals whose patients received it.
SELECT v.name AS vaccine_name,
       COUNT(DISTINCT ph.hospital_id) AS num_hospitals_with_patients_vaccinated
FROM Vaccine v
JOIN PatientImmunization pi ON v.vaccine_id = pi.vaccine_id
JOIN PatientHospital ph     ON pi.patient_id = ph.patient_id
JOIN Hospital h             ON ph.hospital_id = h.hospital_id
GROUP BY v.name
ORDER BY num_hospitals_with_patients_vaccinated DESC;

-- Q30: Doctors, Their Hospital, and Total Vaccines Given to Their Patients
-- Use case: Run Analytics – vaccination volume per doctor
-- Tables involved: 5 (Doctor, Hospital, PatientDoctor, PatientImmunization, Vaccine)
-- Description: For each doctor, count total vaccinations administered to their patients.
SELECT d.doctor_id,
       d.name AS doctor_name,
       h.name AS hospital_name,
       COUNT(DISTINCT pi.patient_id || '-' || pi.vaccine_id) AS total_vaccinations_for_patients
FROM Doctor d
JOIN Hospital h          ON d.hospital_id = h.hospital_id
JOIN PatientDoctor pd    ON d.doctor_id = pd.doctor_id
JOIN PatientImmunization pi ON pd.patient_id = pi.patient_id
JOIN Vaccine v           ON pi.vaccine_id = v.vaccine_id
GROUP BY d.doctor_id, d.name, h.name
ORDER BY total_vaccinations_for_patients DESC;
