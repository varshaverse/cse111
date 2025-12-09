from flask import Flask, render_template, request, redirect, session
import sqlite3

app = Flask(__name__,
            template_folder="templates",
            static_folder="static")

app.secret_key = "super_secret_key_123"


# -------------------------------

# DATABASE CONNECTION
# -------------------------------
def get_db():
    conn = sqlite3.connect(
        "/Users/varsha/Library/Mobile Documents/com~apple~CloudDocs/OneDrive/CSE111/patient_system.db"
    )
    conn.row_factory = sqlite3.Row
    return conn


# -------------------------------
# DOCTOR LOGIN
# -------------------------------
@app.route("/doctor_login", methods=["GET", "POST"])
def doctor_login():
    if request.method == "POST":
        doctor_id = request.form["doctor_id"]
        password = request.form["password"]

        if password != "1234":
            return render_template("doctor_login.html", error="Incorrect password")

        conn = get_db()
        doctor = conn.execute(
            "SELECT * FROM Doctor WHERE doctor_id = ?", (doctor_id,)
        ).fetchone()

        if doctor:
            session["doctor_id"] = doctor_id
            return redirect("/doctor_dashboard")
        else:
            return render_template("doctor_login.html", error="Doctor ID not found")

    return render_template("doctor_login.html")


# -------------------------------
# DOCTOR DASHBOARD
# -------------------------------
@app.route("/doctor_dashboard")
def doctor_dashboard():
    if "doctor_id" not in session:
        return redirect("/doctor_login")

    conn = get_db()

    doctor = conn.execute(
        "SELECT * FROM Doctor WHERE doctor_id = ?", (session["doctor_id"],)
    ).fetchone()

    hospital = conn.execute(
        "SELECT * FROM Hospital WHERE hospital_id = ?", (doctor["hospital_id"],)
    ).fetchone()

    return render_template("doctor_dashboard.html", doctor=doctor, hospital=hospital)


# -------------------------------
# LOOKUP PATIENT
# -------------------------------
@app.route("/lookup_patient", methods=["GET", "POST"])
def lookup_patient():
    patient = None
    if request.method == "POST":
        mrn = request.form["mrn"]
        conn = get_db()
        patient = conn.execute(
            "SELECT * FROM Patient WHERE medical_record_number = ?", (mrn,)
        ).fetchone()
    return render_template("lookup_patient.html", patient=patient)


# -------------------------------
# ADD PATIENT
# -------------------------------
@app.route("/add_patient", methods=["GET", "POST"])
def add_patient():
    message = None
    if request.method == "POST":
        mrn = request.form["mrn"]
        birth_year = request.form["birth_year"]
        gender = request.form["gender"]
        blood_type = request.form["blood_type"]

        conn = get_db()
        conn.execute(
            "INSERT INTO Patient (medical_record_number, birth_year, gender, blood_type) VALUES (?, ?, ?, ?)",
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
    message = None
    if request.method == "POST":
        mrn = request.form["mrn"]
        birth_year = request.form["birth_year"]
        gender = request.form["gender"]
        blood_type = request.form["blood_type"]

        conn = get_db()
        conn.execute(
            "UPDATE Patient SET birth_year=?, gender=?, blood_type=? WHERE medical_record_number=?",
            (birth_year, gender, blood_type, mrn),
        )
        conn.commit()
        message = "Patient successfully updated."

    return render_template("update_patient.html", message=message)


# -------------------------------
# DELETE PATIENT
# -------------------------------
@app.route("/delete_patient", methods=["GET", "POST"])
def delete_patient():
    message = None
    if request.method == "POST":
        mrn = request.form["mrn"]

        conn = get_db()
        conn.execute("DELETE FROM Patient WHERE medical_record_number=?", (mrn,))
        conn.commit()
        message = "Patient successfully deleted."

    return render_template("delete_patient.html", message=message)


# -------------------------------
# BROWSE TABLES
# -------------------------------
@app.route("/browse_tables", methods=["GET", "POST"])
def browse_tables():
    conn = get_db()
    table_data = None
    selected = None

    if request.method == "POST":
        selected = request.form["table_name"]
        table_data = conn.execute(f"SELECT * FROM {selected}").fetchall()

    tables = [
        "Doctor", "Hospital", "Patient",
        "PatientCondition", "PatientDoctor", "PatientHospital",
        "PatientMedications", "PatientImmunization",
        "Conditions", "Medication", "Vaccine"
    ]

    return render_template("browse_tables.html", tables=tables, table_data=table_data, selected=selected)


# -------------------------------
# ANALYTICS
# -------------------------------
@app.route("/analytics")
def analytics():
    conn = get_db()

    common_condition = conn.execute("""
        SELECT c.name, COUNT(*) AS total
        FROM PatientCondition pc
        JOIN Conditions c ON pc.condition_id = c.condition_id
        GROUP BY pc.condition_id
        ORDER BY total DESC LIMIT 1
    """).fetchone()

    common_blood = conn.execute("""
        SELECT blood_type, COUNT(*) AS total
        FROM Patient
        GROUP BY blood_type
        ORDER BY total DESC LIMIT 1
    """).fetchone()

    common_vaccine = conn.execute("""
        SELECT v.name, COUNT(*) AS total
        FROM PatientImmunization pi
        JOIN Vaccine v ON pi.vaccine_id = v.vaccine_id
        GROUP BY pi.vaccine_id
        ORDER BY total DESC LIMIT 1
    """).fetchone()

    return render_template("analytics.html",
                           common_condition=common_condition,
                           common_blood=common_blood,
                           common_vaccine=common_vaccine)


# -------------------------------
# LOGOUT ROUTE
# -------------------------------
@app.route("/logout")
def logout():
    session.clear()
    return redirect("/doctor_login")


# -------------------------------
if __name__ == "__main__":
    app.run(debug=True)
