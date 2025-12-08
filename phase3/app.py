from flask import Flask, render_template, request, redirect, session
import sqlite3
import os
from datetime import date

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "healthcare_analytics.sqlite")

app = Flask(
    __name__,
    template_folder="templates",
    static_folder="static",
)

app.secret_key = "super_secret_key_123"


# -------------------------------
# DB CONNECTION
# -------------------------------
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def require_login():
    return "doctor_id" in session


# -------------------------------
# ROOT → LOGIN
# -------------------------------
@app.route("/")
def index():
    return redirect("/doctor_login")


# -------------------------------
# LOGIN
# -------------------------------
@app.route("/doctor_login", methods=["GET", "POST"])
def doctor_login():
    error = None

    if request.method == "POST":
        doctor_id = request.form["doctor_id"].strip()
        password = request.form["password"]

        conn = get_db()
        cur = conn.execute(
            "SELECT * FROM Doctor WHERE doctor_id = ?",
            (doctor_id,),
        )
        doctor = cur.fetchone()

        # check password against DB
        if doctor and doctor["password"] == password:
            session["doctor_id"] = doctor["doctor_id"]
            return redirect("/doctor_dashboard")
        else:
            error = "Invalid ID or password."

    return render_template("doctor_login.html", error=error)


# -------------------------------
# DOCTOR DASHBOARD
# -------------------------------
@app.route("/doctor_dashboard")
def doctor_dashboard():
    if not require_login():
        return redirect("/doctor_login")

    conn = get_db()
    cur = conn.execute(
        "SELECT * FROM Doctor WHERE doctor_id = ?",
        (session["doctor_id"],),
    )
    doctor = cur.fetchone()
    if doctor is None:
        session.clear()
        return redirect("/doctor_login")

    cur = conn.execute(
        "SELECT * FROM Hospital WHERE hospital_id = ?",
        (doctor["hospital_id"],),
    )
    hospital = cur.fetchone()

    return render_template(
        "doctor_dashboard.html",
        doctor=doctor,
        hospital=hospital,
    )


# -------------------------------
# LOOKUP PATIENT BY MRN
# -------------------------------
@app.route("/lookup_patient", methods=["GET", "POST"])
def lookup_patient():
    if not require_login():
        return redirect("/doctor_login")

    patient = None
    conditions = []
    medications = []
    vaccines = []

    if request.method == "POST":
        mrn = request.form["mrn"].strip()

        conn = get_db()
        # 1. find the patient
        cur = conn.execute(
            "SELECT * FROM Patient WHERE medical_record_number = ?",
            (mrn,),
        )
        patient = cur.fetchone()

        if patient:
            pid = patient["patient_id"]

            # 2. conditions for this patient + meds used for each condition
            conditions = conn.execute(
                '''
                SELECT
                    c.name AS condition_name,
                    pc.diagnosis_date,
                    d.name AS doctor_name,
                    GROUP_CONCAT(DISTINCT m.name) AS medications_for_condition
                FROM PatientCondition pc
                JOIN "Condition" c
                    ON pc.condition_id = c.condition_id
                JOIN Doctor d
                    ON pc.doctor_id = d.doctor_id
                LEFT JOIN MedicationCondition mc
                    ON c.condition_id = mc.condition_id
                LEFT JOIN Medication m
                    ON mc.medication_id = m.medication_id
                WHERE pc.patient_id = ?
                GROUP BY c.condition_id, pc.diagnosis_date, d.name
                ORDER BY pc.diagnosis_date DESC
                ''',
                (pid,),
            ).fetchall()

            # 3. medications for this patient + conditions each med treats
            medications = conn.execute(
                '''
                SELECT
                    m.name AS medication_name,
                    pm.prescription_date,
                    d.name AS doctor_name,
                    GROUP_CONCAT(DISTINCT c.name) AS conditions_for_medication
                FROM PatientMedication pm
                JOIN Medication m
                    ON pm.medication_id = m.medication_id
                JOIN Doctor d
                    ON pm.doctor_id = d.doctor_id
                LEFT JOIN MedicationCondition mc
                    ON m.medication_id = mc.medication_id
                LEFT JOIN "Condition" c
                    ON mc.condition_id = c.condition_id
                WHERE pm.patient_id = ?
                GROUP BY m.medication_id, pm.prescription_date, d.name
                ORDER BY pm.prescription_date DESC
                ''',
                (pid,),
            ).fetchall()

            # 4. vaccines for this patient
            vaccines = conn.execute(
                '''
                SELECT v.name AS vaccine_name,
                       pi.admin_date
                FROM PatientImmunization pi
                JOIN Vaccine v
                    ON pi.vaccine_id = v.vaccine_id
                WHERE pi.patient_id = ?
                ORDER BY pi.admin_date DESC
                ''',
                (pid,),
            ).fetchall()

    return render_template(
        "lookup_patient.html",
        patient=patient,
        conditions=conditions,
        medications=medications,
        vaccines=vaccines,
    )


# -------------------------------
# ADD PATIENT
# -------------------------------
@app.route("/add_patient", methods=["GET", "POST"])
def add_patient():
    if not require_login():
        return redirect("/doctor_login")

    message = None
    if request.method == "POST":
        mrn = request.form["mrn"].strip()
        birth_year = request.form["birth_year"].strip()
        gender = request.form["gender"]
        blood_type = request.form["blood_type"]

        conn = get_db()
        cur = conn.execute(
            "SELECT 1 FROM Patient WHERE medical_record_number = ?",
            (mrn,),
        )
        if cur.fetchone():
            message = "A patient with this MRN already exists."
        else:
            conn.execute(
                "INSERT INTO Patient (medical_record_number, birth_year, gender, blood_type) "
                "VALUES (?, ?, ?, ?)",
                (mrn, birth_year, gender, blood_type),
            )
            conn.commit()
            message = "Patient successfully added."

    return render_template("add_patient.html", message=message)


# -------------------------------
# UPDATE PATIENT
# -------------------------------
@app.route("/update_patient", methods=["GET", "POST"])
def update_patient():
    if not require_login():
        return redirect("/doctor_login")

    message = None
    if request.method == "POST":
        mrn = request.form["mrn"].strip()
        birth_year = request.form["birth_year"].strip()
        gender = request.form["gender"]
        blood_type = request.form["blood_type"]

        conn = get_db()
        cur = conn.execute(
            "UPDATE Patient "
            "SET birth_year = ?, gender = ?, blood_type = ? "
            "WHERE medical_record_number = ?",
            (birth_year, gender, blood_type, mrn),
        )
        conn.commit()

        if cur.rowcount == 0:
            message = "No patient found with that MRN."
        else:
            message = "Patient successfully updated."

    return render_template("update_patient.html", message=message)


# -------------------------------
# DELETE PATIENT (+ CHILD ROWS)
# -------------------------------
@app.route("/delete_patient", methods=["GET", "POST"])
def delete_patient():
    if not require_login():
        return redirect("/doctor_login")

    message = None
    if request.method == "POST":
        mrn = request.form["mrn"].strip()

        conn = get_db()
        cur = conn.execute(
            "SELECT patient_id FROM Patient WHERE medical_record_number = ?",
            (mrn,),
        )
        row = cur.fetchone()

        if row is None:
            message = "No patient found with that MRN."
        else:
            pid = row["patient_id"]

            conn.execute("DELETE FROM PatientDoctor WHERE patient_id = ?", (pid,))
            conn.execute("DELETE FROM PatientHospital WHERE patient_id = ?", (pid,))
            conn.execute("DELETE FROM PatientCondition WHERE patient_id = ?", (pid,))
            conn.execute("DELETE FROM PatientMedication WHERE patient_id = ?", (pid,))
            conn.execute("DELETE FROM PatientImmunization WHERE patient_id = ?", (pid,))

            conn.execute("DELETE FROM Patient WHERE patient_id = ?", (pid,))
            conn.commit()
            message = "Patient and related records deleted."

    return render_template("delete_patient.html", message=message)


# -------------------------------
# ADD CONDITION TO PATIENT
# -------------------------------
@app.route("/add_condition", methods=["GET", "POST"])
def add_condition():
    if not require_login():
        return redirect("/doctor_login")

    conn = get_db()
    all_conditions = conn.execute(
        'SELECT condition_id, name FROM "Condition" ORDER BY name'
    ).fetchall()

    message = None
    if request.method == "POST":
        mrn = request.form["mrn"].strip()
        condition_id = request.form.get("condition_id", "").strip()
        new_condition_name = request.form.get("new_condition_name", "").strip()
        diagnosis_date = request.form["diagnosis_date"].strip()

        if not diagnosis_date:
            diagnosis_date = date.today().isoformat()

        if not condition_id and not new_condition_name:
            message = "Select an existing condition or enter a new one."
        else:
            if new_condition_name:
                cur = conn.execute(
                    'INSERT INTO "Condition" (name) VALUES (?)',
                    (new_condition_name,),
                )
                conn.commit()
                condition_id = cur.lastrowid

            cur = conn.execute(
                "SELECT patient_id FROM Patient WHERE medical_record_number = ?",
                (mrn,),
            )
            patient = cur.fetchone()

            if patient is None:
                message = "No patient found with that MRN."
            else:
                pid = patient["patient_id"]
                doctor_id = session["doctor_id"]

                conn.execute(
                    '''
                    INSERT OR REPLACE INTO PatientCondition
                        (patient_id, condition_id, diagnosis_date, doctor_id)
                    VALUES (?, ?, ?, ?)
                    ''',
                    (pid, condition_id, diagnosis_date, doctor_id),
                )
                conn.commit()
                message = "Condition added/updated for this patient."

    return render_template(
        "add_condition.html",
        conditions=all_conditions,
        message=message,
    )


# -------------------------------
# ADD MEDICATION TO PATIENT
# -------------------------------
@app.route("/add_medication", methods=["GET", "POST"])
def add_medication():
    if not require_login():
        return redirect("/doctor_login")

    conn = get_db()
    all_meds = conn.execute(
        "SELECT medication_id, name FROM Medication ORDER BY name"
    ).fetchall()

    message = None
    if request.method == "POST":
        mrn = request.form["mrn"].strip()
        medication_id = request.form.get("medication_id", "").strip()
        new_med_name = request.form.get("new_medication_name", "").strip()
        prescription_date = request.form["prescription_date"].strip()

        if not prescription_date:
            prescription_date = date.today().isoformat()

        if not medication_id and not new_med_name:
            message = "Select an existing medication or enter a new one."
        else:
            if new_med_name:
                cur = conn.execute(
                    "INSERT INTO Medication (name) VALUES (?)",
                    (new_med_name,),
                )
                conn.commit()
                medication_id = cur.lastrowid

            cur = conn.execute(
                "SELECT patient_id FROM Patient WHERE medical_record_number = ?",
                (mrn,),
            )
            patient = cur.fetchone()

            if patient is None:
                message = "No patient found with that MRN."
            else:
                pid = patient["patient_id"]
                doctor_id = session["doctor_id"]

                conn.execute(
                    '''
                    INSERT INTO PatientMedication
                        (patient_id, medication_id, prescription_date, doctor_id)
                    VALUES (?, ?, ?, ?)
                    ''',
                    (pid, medication_id, prescription_date, doctor_id),
                )
                conn.commit()
                message = "Medication added to patient history."

    return render_template(
        "add_medication.html",
        medications=all_meds,
        message=message,
    )

@app.route("/delete_condition", methods=["GET", "POST"])
def delete_condition():
    if not require_login():
        return redirect("/doctor_login")

    patient = None
    conditions = []
    message = None

    conn = get_db()

    if request.method == "POST":
        # If this POST has pc_id, we're deleting a specific record
        if "pc_id" in request.form:
            pc_id = request.form["pc_id"]
            mrn = request.form["mrn"].strip()

            conn.execute(
                "DELETE FROM PatientCondition WHERE rowid = ?",
                (pc_id,),
            )
            conn.commit()
            message = "Condition removed from patient record."

            # Re-fetch patient + remaining conditions
            cur = conn.execute(
                "SELECT * FROM Patient WHERE medical_record_number = ?",
                (mrn,),
            )
            patient = cur.fetchone()

            if patient:
                cur = conn.execute(
                    '''
                    SELECT pc.rowid AS pc_id,
                           c.name AS condition_name,
                           pc.diagnosis_date,
                           d.name AS doctor_name
                    FROM PatientCondition pc
                    JOIN "Condition" c ON pc.condition_id = c.condition_id
                    LEFT JOIN Doctor d ON pc.doctor_id = d.doctor_id
                    WHERE pc.patient_id = ?
                    ORDER BY pc.diagnosis_date DESC
                    ''',
                    (patient["patient_id"],),
                )
                conditions = cur.fetchall()

        # Otherwise, this POST is just searching by MRN
        else:
            mrn = request.form["mrn"].strip()

            cur = conn.execute(
                "SELECT * FROM Patient WHERE medical_record_number = ?",
                (mrn,),
            )
            patient = cur.fetchone()

            if not patient:
                message = "No patient found with that MRN."
            else:
                cur = conn.execute(
                    '''
                    SELECT pc.rowid AS pc_id,
                           c.name AS condition_name,
                           pc.diagnosis_date,
                           d.name AS doctor_name
                    FROM PatientCondition pc
                    JOIN "Condition" c ON pc.condition_id = c.condition_id
                    LEFT JOIN Doctor d ON pc.doctor_id = d.doctor_id
                    WHERE pc.patient_id = ?
                    ORDER BY pc.diagnosis_date DESC
                    ''',
                    (patient["patient_id"],),
                )
                conditions = cur.fetchall()

    return render_template(
        "delete_condition.html",
        patient=patient,
        conditions=conditions,
        message=message,
    )
@app.route("/delete_medication", methods=["GET", "POST"])
def delete_medication():
    if not require_login():
        return redirect("/doctor_login")

    patient = None
    meds = []
    message = None

    conn = get_db()

    if request.method == "POST":
        # Deleting a specific medication entry
        if "pm_id" in request.form:
            pm_id = request.form["pm_id"]
            mrn = request.form["mrn"].strip()

            conn.execute(
                "DELETE FROM PatientMedication WHERE rowid = ?",
                (pm_id,),
            )
            conn.commit()
            message = "Medication removed from patient record."

            # Re-fetch patient + remaining meds
            cur = conn.execute(
                "SELECT * FROM Patient WHERE medical_record_number = ?",
                (mrn,),
            )
            patient = cur.fetchone()

            if patient:
                cur = conn.execute(
                    '''
                    SELECT pm.rowid AS pm_id,
                           m.name AS medication_name,
                           pm.prescription_date,
                           d.name AS doctor_name
                    FROM PatientMedication pm
                    JOIN Medication m ON pm.medication_id = m.medication_id
                    LEFT JOIN Doctor d ON pm.doctor_id = d.doctor_id
                    WHERE pm.patient_id = ?
                    ORDER BY pm.prescription_date DESC
                    ''',
                    (patient["patient_id"],),
                )
                meds = cur.fetchall()

        # Searching by MRN
        else:
            mrn = request.form["mrn"].strip()

            cur = conn.execute(
                "SELECT * FROM Patient WHERE medical_record_number = ?",
                (mrn,),
            )
            patient = cur.fetchone()

            if not patient:
                message = "No patient found with that MRN."
            else:
                cur = conn.execute(
                    '''
                    SELECT pm.rowid AS pm_id,
                           m.name AS medication_name,
                           pm.prescription_date,
                           d.name AS doctor_name
                    FROM PatientMedication pm
                    JOIN Medication m ON pm.medication_id = m.medication_id
                    LEFT JOIN Doctor d ON pm.doctor_id = d.doctor_id
                    WHERE pm.patient_id = ?
                    ORDER BY pm.prescription_date DESC
                    ''',
                    (patient["patient_id"],),
                )
                meds = cur.fetchall()

    return render_template(
        "delete_medication.html",
        patient=patient,
        meds=meds,
        message=message,
    )


# -------------------------------
# ADD VACCINE TO PATIENT
# -------------------------------
@app.route("/add_vaccine", methods=["GET", "POST"])
def add_vaccine():
    if not require_login():
        return redirect("/doctor_login")

    conn = get_db()
    all_vaccines = conn.execute(
        "SELECT vaccine_id, name FROM Vaccine ORDER BY name"
    ).fetchall()

    message = None
    if request.method == "POST":
        mrn = request.form["mrn"].strip()
        vaccine_id = request.form.get("vaccine_id", "").strip()
        new_vaccine_name = request.form.get("new_vaccine_name", "").strip()
        admin_date = request.form["admin_date"].strip()

        if not admin_date:
            admin_date = date.today().isoformat()

        if not vaccine_id and not new_vaccine_name:
            message = "Select an existing vaccine or enter a new one."
        else:
            if new_vaccine_name:
                cur = conn.execute(
                    "INSERT INTO Vaccine (name) VALUES (?)",
                    (new_vaccine_name,),
                )
                conn.commit()
                vaccine_id = cur.lastrowid

            cur = conn.execute(
                "SELECT patient_id FROM Patient WHERE medical_record_number = ?",
                (mrn,),
            )
            patient = cur.fetchone()

            if patient is None:
                message = "No patient found with that MRN."
            else:
                pid = patient["patient_id"]

                conn.execute(
                    '''
                    INSERT INTO PatientImmunization
                        (patient_id, vaccine_id, admin_date)
                    VALUES (?, ?, ?)
                    ''',
                    (pid, vaccine_id, admin_date),
                )
                conn.commit()
                message = "Vaccine added to patient history."

    return render_template(
        "add_vaccine.html",
        vaccines=all_vaccines,
        message=message,
    )


# -------------------------------
# BROWSE TABLES
# -------------------------------
# -------------------------------
# BROWSE TABLES
# -------------------------------
TABLE_WHITELIST = [
    "Hospital",
    "Doctor",
    "Patient",
    "Condition",          # actual table name is "Condition"
    "Medication",
    "Vaccine",
    "PatientDoctor",
    "PatientHospital",
    "PatientCondition",
    "PatientMedication",
    "PatientImmunization",
    "MedicationCondition",
]


@app.route("/browse_tables", methods=["GET", "POST"])
def browse_tables():
    if not require_login():
        return redirect("/doctor_login")

    selected = None
    table_data = None
    columns = None

    if request.method == "POST":
        selected = request.form["table_name"]
        conn = get_db()

        # More informative + sorted views for relationship tables
        if selected == "PatientHospital":
            sql = """
                SELECT
                    ph.patient_id,
                    p.medical_record_number,
                    ph.hospital_id,
                    h.name AS hospital_name,
                    h.city AS hospital_city
                FROM PatientHospital ph
                JOIN Patient p ON ph.patient_id = p.patient_id
                JOIN Hospital h ON ph.hospital_id = h.hospital_id
                ORDER BY
                    p.medical_record_number,
                    h.name

            """
        elif selected == "PatientCondition":
            sql = """
                SELECT
                    pc.patient_id,
                    p.medical_record_number,
                    c.name AS condition_name,
                    pc.diagnosis_date,
                    d.name AS doctor_name
                FROM PatientCondition pc
                JOIN Patient p ON pc.patient_id = p.patient_id
                JOIN "Condition" c ON pc.condition_id = c.condition_id
                JOIN Doctor d ON pc.doctor_id = d.doctor_id
                ORDER BY
                    p.medical_record_number,
                    c.name,
                    pc.diagnosis_date DESC
            """
        elif selected == "PatientMedication":
            sql = """
                SELECT
                    pm.patient_id,
                    p.medical_record_number,
                    m.name AS medication_name,
                    pm.prescription_date,
                    d.name AS doctor_name
                FROM PatientMedication pm
                JOIN Patient p ON pm.patient_id = p.patient_id
                JOIN Medication m ON pm.medication_id = m.medication_id
                JOIN Doctor d ON pm.doctor_id = d.doctor_id
                ORDER BY
                    p.medical_record_number,
                    pm.prescription_date DESC,
                    m.name
            """
        elif selected == "PatientImmunization":
            sql = """
                SELECT
                    pi.patient_id,
                    p.medical_record_number,
                    v.name AS vaccine_name,
                    pi.admin_date
                FROM PatientImmunization pi
                JOIN Patient p ON pi.patient_id = p.patient_id
                JOIN Vaccine v ON pi.vaccine_id = v.vaccine_id
                ORDER BY
                    p.medical_record_number,
                    pi.admin_date DESC,
                    v.name
            """
        elif selected == "MedicationCondition":
            sql = """
                SELECT
                    mc.medication_id,
                    m.name AS medication_name,
                    mc.condition_id,
                    c.name AS condition_name
                FROM MedicationCondition mc
                JOIN Medication m ON mc.medication_id = m.medication_id
                JOIN "Condition" c ON mc.condition_id = c.condition_id
                ORDER BY
                    m.name,
                    c.name
            """
        elif selected == "PatientDoctor":
            sql = """
                SELECT
                    pd.patient_id,
                    p.medical_record_number,
                    pd.doctor_id,
                    d.name AS doctor_name,
                    d.specialty AS doctor_specialty,
                    h.name AS hospital_name,
                    h.city AS hospital_city
                FROM PatientDoctor pd
                JOIN Patient p ON pd.patient_id = p.patient_id
                JOIN Doctor d ON pd.doctor_id = d.doctor_id
                JOIN Hospital h ON d.hospital_id = h.hospital_id
                ORDER BY
                    d.name,
                    p.medical_record_number
            """
        elif selected == "Doctor":
            # Hide password; show hospital info instead
            sql = """
                SELECT
                    d.doctor_id,
                    d.name,
                    d.specialty,
                    h.name AS hospital_name,
                    h.city AS hospital_city
                FROM Doctor d
                JOIN Hospital h ON d.hospital_id = h.hospital_id
                ORDER BY
                    d.name
            """
        else:
            # Default: simple SELECT * (with proper quoting for Condition)
            if selected == "Condition":
                sql_table = '"Condition"'
            else:
                sql_table = selected
            sql = f"SELECT * FROM {sql_table}"

        cur = conn.execute(sql)
        table_data = cur.fetchall()
        columns = [desc[0] for desc in cur.description]

    return render_template(
        "browse_tables.html",
        tables=TABLE_WHITELIST,
        selected=selected,
        table_data=table_data,
        columns=columns,
    )



# -------------------------------
# ANALYTICS
# -------------------------------
# -------------------------------
# ANALYTICS
# -------------------------------
@app.route("/analytics")
def analytics():
    if not require_login():
        return redirect("/doctor_login")

    conn = get_db()

    # Simple "most common" stats for potential cards (you can ignore in HTML if not used)
    common_condition = conn.execute(
        '''
        SELECT c.name, COUNT(*) AS total
        FROM PatientCondition pc
        JOIN "Condition" c ON pc.condition_id = c.condition_id
        GROUP BY c.condition_id
        ORDER BY total DESC
        LIMIT 1
        '''
    ).fetchone()

    common_blood = conn.execute(
        '''
        SELECT blood_type, COUNT(*) AS total
        FROM Patient
        GROUP BY blood_type
        ORDER BY total DESC
        LIMIT 1
        '''
    ).fetchone()

    common_vaccine = conn.execute(
        '''
        SELECT v.name, COUNT(*) AS total
        FROM PatientImmunization pi
        JOIN Vaccine v ON pi.vaccine_id = v.vaccine_id
        GROUP BY v.vaccine_id
        ORDER BY total DESC
        LIMIT 1
        '''
    ).fetchone()

    # TOP 5 conditions by distinct patients (bar chart)
    cond_rows = conn.execute(
        '''
        SELECT c.name AS condition_name,
               COUNT(DISTINCT pc.patient_id) AS total_patients
        FROM PatientCondition pc
        JOIN "Condition" c ON pc.condition_id = c.condition_id
        GROUP BY c.condition_id
        ORDER BY total_patients DESC
        LIMIT 5
        '''
    ).fetchall()
    cond_labels = [row["condition_name"] for row in cond_rows]
    cond_values = [row["total_patients"] for row in cond_rows]

    # Most prevalent gender per condition (table)
    gender_top = conn.execute(
        '''
        SELECT condition_name, gender, total
        FROM (
            SELECT
                c.name AS condition_name,
                p.gender,
                COUNT(*) AS total,
                ROW_NUMBER() OVER (
                    PARTITION BY c.condition_id
                    ORDER BY COUNT(*) DESC
                ) AS rn
            FROM PatientCondition pc
            JOIN Patient p ON pc.patient_id = p.patient_id
            JOIN "Condition" c ON pc.condition_id = c.condition_id
            GROUP BY c.condition_id, p.gender
        )
        WHERE rn = 1
        ORDER BY total DESC;
        '''
    ).fetchall()

    # Most prevalent blood type per condition (table)
    blood_top = conn.execute(
        '''
        SELECT condition_name, blood_type, total
        FROM (
            SELECT
                c.name AS condition_name,
                p.blood_type,
                COUNT(*) AS total,
                ROW_NUMBER() OVER (
                    PARTITION BY c.condition_id
                    ORDER BY COUNT(*) DESC
                ) AS rn
            FROM PatientCondition pc
            JOIN Patient p ON pc.patient_id = p.patient_id
            JOIN "Condition" c ON pc.condition_id = c.condition_id
            GROUP BY c.condition_id, p.blood_type
        )
        WHERE rn = 1
        ORDER BY total DESC;
        '''
    ).fetchall()

    # Vaccine uptake: how many patients got each vaccine (bar chart)
    vaccine_rows = conn.execute(
        '''
        SELECT v.name AS vaccine_name,
               COUNT(DISTINCT pi.patient_id) AS total_patients
        FROM PatientImmunization pi
        JOIN Vaccine v ON pi.vaccine_id = v.vaccine_id
        GROUP BY v.vaccine_id
        ORDER BY total_patients DESC;
        '''
    ).fetchall()
    vaccine_labels = [row["vaccine_name"] for row in vaccine_rows]
    vaccine_values = [row["total_patients"] for row in vaccine_rows]

    # Age groups from birth_year (pie chart)
    all_birth_years = conn.execute(
        '''
        SELECT birth_year
        FROM Patient
        WHERE birth_year IS NOT NULL
        '''
    ).fetchall()

    from datetime import date
    current_year = date.today().year

    age_bins = {
        "0-17": 0,
        "18-34": 0,
        "35-49": 0,
        "50-64": 0,
        "65+": 0,
    }

    for row in all_birth_years:
        by = row["birth_year"]
        if not by:
            continue
        age = current_year - by
        if age <= 17:
            age_bins["0-17"] += 1
        elif age <= 34:
            age_bins["18-34"] += 1
        elif age <= 49:
            age_bins["35-49"] += 1
        elif age <= 64:
            age_bins["50-64"] += 1
        else:
            age_bins["65+"] += 1

    age_labels = list(age_bins.keys())
    age_values = list(age_bins.values())

    # 🔹 NEW: Average age per condition (bar chart)
    avg_age_rows = conn.execute(
        """
        SELECT
            c.name AS condition_name,
            AVG(CAST(strftime('%Y','now') AS INTEGER) - p.birth_year) AS avg_age
        FROM PatientCondition pc
        JOIN Patient p ON pc.patient_id = p.patient_id
        JOIN "Condition" c ON pc.condition_id = c.condition_id
        WHERE p.birth_year IS NOT NULL
        GROUP BY c.condition_id
        ORDER BY avg_age DESC;
        """
    ).fetchall()
    avg_age_labels = [row["condition_name"] for row in avg_age_rows]
    # round to one decimal for nicer display
    avg_age_values = [round(row["avg_age"], 1) for row in avg_age_rows]

    # 🔹 NEW: Most common condition per hospital (table)
    hospital_top = conn.execute(
        """
        WITH cond_counts AS (
            SELECT
                h.name AS hospital_name,
                c.name AS condition_name,
                COUNT(DISTINCT ph.patient_id) AS total
            FROM PatientHospital ph
            JOIN PatientCondition pc ON ph.patient_id = pc.patient_id
            JOIN "Condition" c ON pc.condition_id = c.condition_id
            JOIN Hospital h ON ph.hospital_id = h.hospital_id
            GROUP BY h.hospital_id, c.condition_id
        ),
        ranked AS (
            SELECT
                hospital_name,
                condition_name,
                total,
                ROW_NUMBER() OVER (
                    PARTITION BY hospital_name
                    ORDER BY total DESC
                ) AS rn
            FROM cond_counts
        )
        SELECT hospital_name, condition_name, total
        FROM ranked
        WHERE rn = 1
        ORDER BY hospital_name;
        """
    ).fetchall()

    return render_template(
        "analytics.html",
        common_condition=common_condition,
        common_blood=common_blood,
        common_vaccine=common_vaccine,
        cond_labels=cond_labels,
        cond_values=cond_values,
        gender_top=gender_top,
        blood_top=blood_top,
        vaccine_labels=vaccine_labels,
        vaccine_values=vaccine_values,
        age_labels=age_labels,
        age_values=age_values,
        avg_age_labels=avg_age_labels,
        avg_age_values=avg_age_values,
        hospital_top=hospital_top,
    )



# -------------------------------
# LOGOUT
# -------------------------------
@app.route("/logout")
def logout():
    session.clear()
    return redirect("/doctor_login")


if __name__ == "__main__":
    app.run(debug=True)


