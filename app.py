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

        # Special JOIN logic for more informative views
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
            """

        elif selected == "Doctor":
            # Hide password; show hospital details instead
            sql = """
                SELECT
                    d.doctor_id,
                    d.name,
                    d.specialty,
                    h.name AS hospital_name,
                    h.city AS hospital_city
                FROM Doctor d
                JOIN Hospital h ON d.hospital_id = h.hospital_id
            """
        else:
            # Default: simple SELECT *
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
@app.route("/analytics")
def analytics():
    if not require_login():
        return redirect("/doctor_login")

    conn = get_db()

    common_condition = conn.execute(
        'SELECT c.name, COUNT(*) AS total '
        'FROM PatientCondition pc '
        'JOIN "Condition" c ON pc.condition_id = c.condition_id '
        'GROUP BY c.condition_id '
        'ORDER BY total DESC '
        'LIMIT 1'
    ).fetchone()

    common_blood = conn.execute(
        "SELECT blood_type, COUNT(*) AS total "
        "FROM Patient "
        "GROUP BY blood_type "
        "ORDER BY total DESC "
        "LIMIT 1"
    ).fetchone()

    common_vaccine = conn.execute(
        "SELECT v.name, COUNT(*) AS total "
        "FROM PatientImmunization pi "
        "JOIN Vaccine v ON pi.vaccine_id = v.vaccine_id "
        "GROUP BY v.vaccine_id "
        "ORDER BY total DESC "
        "LIMIT 1"
    ).fetchone()

    return render_template(
        "analytics.html",
        common_condition=common_condition,
        common_blood=common_blood,
        common_vaccine=common_vaccine,
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


