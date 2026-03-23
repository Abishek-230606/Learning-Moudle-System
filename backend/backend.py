import os
from flask import Flask, render_template, request, redirect, url_for, jsonify, session
import mysql.connector

app = Flask(__name__, template_folder='../frontend', static_folder='../frontend', static_url_path='/')
app.secret_key = 'learning_module_system_secret'

DB_CONFIG = {
    "host": os.getenv("LMS_DB_HOST", "localhost"),
    "port": int(os.getenv("LMS_DB_PORT", "3306")),
    "user": os.getenv("LMS_DB_USER", "root"),
    "password": os.getenv("LMS_DB_PASSWORD", "Sathishdhana#23"),
    "database": os.getenv("LMS_DB_NAME", "lms_db"),
}

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

def get_enrollment_status(user_id, course_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT status FROM Enrollment WHERE user_id = %s AND course_id = %s",
        (user_id, course_id)
    )
    enrollment = cursor.fetchone()
    cursor.close()
    conn.close()
    return enrollment['status'] if enrollment else None

def get_course_id_for_module(module_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT course_id FROM Module WHERE module_id = %s", (module_id,))
    module = cursor.fetchone()
    cursor.close()
    conn.close()
    return module['course_id'] if module else None

@app.route('/')
def public_home():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT c.course_id, c.title, c.description, c.duration, c.level,
               COUNT(m.module_id) AS module_count
        FROM Course c
        LEFT JOIN Module m ON c.course_id = m.course_id
        GROUP BY c.course_id, c.title, c.description, c.duration, c.level
        ORDER BY c.created_at DESC
    """)
    courses = cursor.fetchall()
    cursor.execute("SELECT COUNT(*) AS count FROM Course")
    total_courses = cursor.fetchone()['count']
    cursor.execute("SELECT COUNT(*) AS count FROM User WHERE role = 'STUDENT'")
    total_students = cursor.fetchone()['count']
    cursor.execute("SELECT COUNT(*) AS count FROM Certificate")
    total_certificates = cursor.fetchone()['count']
    cursor.close()
    conn.close()
    return render_template(
        'landing.html',
        courses=courses,
        total_courses=total_courses,
        total_students=total_students,
        total_certificates=total_certificates
    )

@app.route('/catalog/course/<int:course_id>')
def public_course(course_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Course WHERE course_id = %s", (course_id,))
    course = cursor.fetchone()
    if not course:
        cursor.close()
        conn.close()
        return redirect(url_for('public_home'))

    cursor.execute("""
        SELECT module_id, module_title, module_order, module_type
        FROM Module
        WHERE course_id = %s
        ORDER BY module_order ASC
    """, (course_id,))
    modules = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('public_course.html', course=course, modules=modules, error=None, form_data={})

@app.route('/apply/<int:course_id>', methods=['POST'])
def apply_course(course_id):
    name = request.form.get('name', '').strip()
    email = request.form.get('email', '').strip()
    password = request.form.get('password', '').strip()

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Course WHERE course_id = %s", (course_id,))
    course = cursor.fetchone()
    if not course:
        cursor.close()
        conn.close()
        return redirect(url_for('public_home'))

    cursor.execute("""
        SELECT module_id, module_title, module_order, module_type
        FROM Module
        WHERE course_id = %s
        ORDER BY module_order ASC
    """, (course_id,))
    modules = cursor.fetchall()

    if not name or not email or not password:
        cursor.close()
        conn.close()
        return render_template(
            'public_course.html',
            course=course,
            modules=modules,
            error="Please fill in your name, email, and password to request access.",
            form_data={"name": name, "email": email}
        )

    try:
        cursor.execute("SELECT * FROM User WHERE email = %s", (email,))
        existing_user = cursor.fetchone()

        if existing_user:
            if existing_user['role'] != 'STUDENT':
                raise ValueError("This email is already used by an admin account. Please use another email.")
            if existing_user['password'] != password:
                raise ValueError("An account with this email already exists. Please login with that account.")
            user_id = existing_user['user_id']
        else:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO User (name, email, password, role) VALUES (%s, %s, %s, 'STUDENT')",
                (name, email, password)
            )
            user_id = cursor.lastrowid
            cursor = conn.cursor(dictionary=True)

        cursor.execute(
            "SELECT status FROM Enrollment WHERE user_id = %s AND course_id = %s",
            (user_id, course_id)
        )
        existing_enrollment = cursor.fetchone()

        if existing_enrollment:
            status = existing_enrollment['status']
            if status == 'PENDING':
                raise ValueError("Your request for this course is already pending admin approval.")
            raise ValueError("You already have access to this course. Please login to continue.")

        plain_cursor = conn.cursor()
        plain_cursor.execute(
            "INSERT INTO Enrollment (user_id, course_id, enrolled_date, status) VALUES (%s, %s, CURDATE(), 'PENDING')",
            (user_id, course_id)
        )
        conn.commit()
        plain_cursor.close()
        cursor.close()
        conn.close()
        return redirect(url_for('application_thanks', course_title=course['title'], student_name=name))
    except ValueError as err:
        cursor.close()
        conn.close()
        return render_template(
            'public_course.html',
            course=course,
            modules=modules,
            error=str(err),
            form_data={"name": name, "email": email}
        )
    except mysql.connector.Error as err:
        cursor.close()
        conn.close()
        return render_template(
            'public_course.html',
            course=course,
            modules=modules,
            error=f"Unable to send your request right now: {err}",
            form_data={"name": name, "email": email}
        )

@app.route('/application-thanks')
def application_thanks():
    return render_template(
        'application_thanks.html',
        course_title=request.args.get('course_title', 'your selected course'),
        student_name=request.args.get('student_name', 'Learner')
    )

@app.route('/admin_login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM User WHERE email = %s AND password = %s AND role = 'ADMIN'", (email, password))
        admin_user = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if admin_user:
            session['user_id'] = admin_user['user_id']
            session['name'] = admin_user['name']
            session['role'] = admin_user['role']
            return redirect(url_for('admin'))
        else:
            return render_template('admin_login.html', error="Invalid Admin Credentials")
            
    return render_template('admin_login.html')

@app.route('/admin.html')
def admin():
    if 'user_id' not in session or session.get('role') != 'ADMIN':
        return redirect(url_for('admin_login'))
        
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    # 1. Total Active Students
    cursor.execute("SELECT COUNT(*) as count FROM User WHERE role='STUDENT'")
    total_students = cursor.fetchone()['count']
    
    # 2. Total Enrollments Check
    cursor.execute("SELECT COUNT(*) as count FROM Enrollment")
    total_enrollment = cursor.fetchone()['count']
    
    # 3. Pending Projects Check
    cursor.execute("SELECT COUNT(*) as count FROM Project_Submission WHERE status='PENDING'")
    total_pending = cursor.fetchone()['count']
    
    # Generate charts data
    cursor.execute("""
        SELECT DATE_FORMAT(enrolled_date, '%%M') AS label, COUNT(*) AS data
        FROM Enrollment
        GROUP BY YEAR(enrolled_date), MONTH(enrolled_date), DATE_FORMAT(enrolled_date, '%%M')
        ORDER BY YEAR(enrolled_date), MONTH(enrolled_date)
    """)
    chart_data = cursor.fetchall()
    labels = [row['label'] for row in chart_data]
    data = [row['data'] for row in chart_data]
    
    # Recent enrollments
    cursor.execute("""
        SELECT e.enrollment_id, u.name as student_name, c.title as course_title, e.enrolled_date 
        FROM Enrollment e
        JOIN User u ON e.user_id = u.user_id
        JOIN Course c ON e.course_id = c.course_id
        WHERE e.status = 'ACTIVE'
        ORDER BY e.enrolled_date DESC LIMIT 5
    """)
    recent_enrollments = cursor.fetchall()

    # Pending course invitations
    cursor.execute("""
        SELECT e.enrollment_id, u.name as student_name, c.title as course_title, e.enrolled_date 
        FROM Enrollment e
        JOIN User u ON e.user_id = u.user_id
        JOIN Course c ON e.course_id = c.course_id
        WHERE e.status = 'PENDING'
        ORDER BY e.enrolled_date ASC
    """)
    pending_invites = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('admin.html',
                           total_students=total_students,
                           total_enrollment=total_enrollment,
                           total_pending=total_pending,
                           labels=labels,
                           data=data,
                           recent_enrollments=recent_enrollments,
                           pending_invites=pending_invites)

@app.route('/approve_enrollment', methods=['POST'])
def approve_enrollment():
    enrollment_id = request.form.get('enrollment_id')
    if enrollment_id:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE Enrollment SET status='ACTIVE' WHERE enrollment_id=%s", (enrollment_id,))
        conn.commit()
        cursor.close()
        conn.close()
    return redirect(url_for('admin'))

@app.route('/students.html')
def students():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT user_id, name, email, role FROM User WHERE role = 'STUDENT'")
    students_list = cursor.fetchall()
    
    cursor.execute("SELECT course_id, title FROM Course")
    courses_list = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return render_template('students.html', students=students_list, courses=courses_list)

@app.route('/add_student', methods=['POST'])
def add_student():
    name = request.form.get('name')
    email = request.form.get('email')
    password = request.form.get('password')
    course_id = request.form.get('course_id')
    
    if name and email and password:
        conn = get_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO User (name, email, password, role) VALUES (%s, %s, %s, 'STUDENT')",
                (name, email, password)
            )
            user_id = cursor.lastrowid
            
            if course_id:
                cursor.execute(
                    "INSERT INTO Enrollment (user_id, course_id, enrolled_date, status) VALUES (%s, %s, CURDATE(), 'ACTIVE')",
                    (user_id, course_id)
                )
            
            conn.commit()
        except mysql.connector.Error as err:
            print(f"Error: {err}")
        finally:
            cursor.close()
            conn.close()
            
    return redirect(url_for('students'))

@app.route('/courses.html')
def courses():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT course_id, title, description, duration, level FROM Course")
    courses_list = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('courses.html', courses=courses_list)

@app.route('/add_course', methods=['POST'])
def add_course():
    title = request.form.get('title')
    description = request.form.get('description')
    duration = request.form.get('duration')
    level = request.form.get('level')
    
    if title and description and duration and level:
        conn = get_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO Course (title, description, duration, level) VALUES (%s, %s, %s, %s)",
                (title, description, duration, level)
            )
            conn.commit()
        except mysql.connector.Error as err:
            print(f"Error: {err}")
        finally:
            cursor.close()
            conn.close()
            
    return redirect(url_for('courses'))

@app.route('/projects.html')
def projects():
    if 'user_id' not in session or session.get('role') != 'ADMIN': return redirect(url_for('admin_login'))
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("""
        SELECT p.submission_id, p.user_id, p.module_id, u.name AS student_name,
               c.title AS course_title, m.module_title, p.github_link,
               p.submitted_date, p.status, cert.certificate_code
        FROM Project_Submission p
        JOIN User u ON p.user_id = u.user_id
        JOIN Module m ON p.module_id = m.module_id
        JOIN Course c ON m.course_id = c.course_id
        LEFT JOIN Certificate cert
            ON cert.user_id = p.user_id AND cert.course_id = c.course_id
        ORDER BY p.submitted_date DESC
    """)
    projects = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return render_template('projects.html', projects=projects)

@app.route('/admin/student/<int:student_id>')
def admin_student_view(student_id):
    if 'user_id' not in session or session.get('role') != 'ADMIN': return redirect(url_for('admin_login'))
    
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM User WHERE user_id = %s", (student_id,))
    student = cursor.fetchone()
    
    cursor.execute("""
        SELECT c.title, e.enrolled_date, e.status, e.progress_percentage
        FROM Enrollment e
        JOIN Course c ON e.course_id = c.course_id
        WHERE e.user_id = %s
    """, (student_id,))
    enrollments = cursor.fetchall()
    
    cursor.execute("""
        SELECT q.quiz_title, c.title AS course_title, qa.score,
               CASE WHEN qa.score >= q.pass_marks THEN 1 ELSE 0 END AS passed,
               qa.attempt_date
        FROM Quiz_Attempt qa
        JOIN Quiz q ON qa.quiz_id = q.quiz_id
        JOIN Module m ON q.module_id = m.module_id
        JOIN Course c ON m.course_id = c.course_id
        WHERE qa.user_id = %s
    """, (student_id,))
    quizzes = cursor.fetchall()
    
    cursor.execute("""
        SELECT m.module_title, p.github_link, p.status, p.submitted_date
        FROM Project_Submission p
        JOIN Module m ON p.module_id = m.module_id
        WHERE p.user_id = %s
    """, (student_id,))
    projects = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return render_template('admin_student_view.html', student=student, enrollments=enrollments, quizzes=quizzes, projects=projects)

@app.route('/admin/course/<int:course_id>')
def admin_course_edit(course_id):
    if 'user_id' not in session or session.get('role') != 'ADMIN': return redirect(url_for('admin_login'))
    
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Course WHERE course_id = %s", (course_id,))
    course = cursor.fetchone()
    
    cursor.execute("""
        SELECT m.*, v.video_url, v.video_id, q.quiz_id, (SELECT COUNT(*) FROM Question qq WHERE qq.quiz_id = q.quiz_id) as q_count
        FROM Module m
        LEFT JOIN Video v ON m.module_id = v.module_id
        LEFT JOIN Quiz q ON m.module_id = q.module_id
        WHERE m.course_id = %s ORDER BY m.module_order
    """, (course_id,))
    modules = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    success = request.args.get('success')
    return render_template('admin_course_edit.html', course=course, modules=modules, success=success)

@app.route('/admin/update_video', methods=['POST'])
def admin_update_video():
    if session.get('role') != 'ADMIN': return redirect(url_for('admin_login'))
    video_id = request.form.get('video_id')
    new_url = request.form.get('video_url')
    course_id = request.form.get('course_id')
    
    if video_id and new_url:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE Video SET video_url = %s WHERE video_id = %s", (new_url, video_id))
        conn.commit()
        cursor.close()
        conn.close()
    return redirect(url_for('admin_course_edit', course_id=course_id, success="Video URL Updated Successfully!"))

@app.route('/verify_project', methods=['POST'])
def verify_project():
    data = request.get_json()
    user_id = data.get('user_id')
    module_id = data.get('module_id')
    action = data.get('action') # 'verify' or 'reject'
    
    if user_id and module_id and action:
        status_val = 'APPROVED' if action == 'verify' else 'REJECTED'
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(
                "UPDATE Project_Submission SET status = %s WHERE user_id = %s AND module_id = %s",
                (status_val, user_id, module_id)
            )
            conn.commit()
            
            # Fetch the new certificate if it was generated
            cursor.execute("""
                SELECT C.certificate_code 
                FROM Certificate C
                JOIN Module M ON C.course_id = M.course_id
                WHERE C.user_id = %s AND M.module_id = %s
            """, (user_id, module_id))
            cert = cursor.fetchone()
            cert_code = cert['certificate_code'] if cert else None
            
            return jsonify({"success": True, "status": status_val, "certificate_code": cert_code}), 200
        except mysql.connector.Error as err:
            print(f"Error: {err}")
            return jsonify({"success": False, "error": str(err)}), 500
        finally:
            cursor.close()
            conn.close()
            
    return jsonify({"success": False, "error": "Invalid data"}), 400

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM User WHERE email = %s AND password = %s", (email, password))
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if user:
            session['user_id'] = user['user_id']
            session['role'] = user['role']
            session['name'] = user['name']
            if user['role'] == 'ADMIN':
                return redirect(url_for('admin'))
            else:
                return redirect(url_for('dashboard'))
        else:
            error = "Invalid email or password. Please try again."
            
    return render_template('student_login.html', error=error)

@app.route('/admin/invitations')
def admin_invitations():
    if 'user_id' not in session or session.get('role') != 'ADMIN': return redirect(url_for('admin_login'))
    
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT e.enrollment_id, u.name as student_name, c.title as course_title, e.enrolled_date 
        FROM Enrollment e
        JOIN User u ON e.user_id = u.user_id
        JOIN Course c ON e.course_id = c.course_id
        WHERE e.status = 'PENDING'
        ORDER BY e.enrolled_date ASC
    """)
    pending_invites = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('admin_invitations.html', pending_invites=pending_invites)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session or session['role'] != 'STUDENT':
        return redirect(url_for('login'))
        
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("""
        SELECT C.course_id, C.title, C.level, E.enrolled_date, E.status, E.progress_percentage
        FROM Enrollment E
        JOIN Course C ON E.course_id = C.course_id
        WHERE E.user_id = %s
        ORDER BY FIELD(E.status, 'ACTIVE', 'COMPLETED', 'PENDING'), E.enrolled_date DESC
    """, (session['user_id'],))
    enrollments = cursor.fetchall()
    
    cursor.execute("""
        SELECT C.title, Cert.issue_date, Cert.certificate_code
        FROM Certificate Cert
        JOIN Course C ON Cert.course_id = C.course_id
        WHERE Cert.user_id = %s
    """, (session['user_id'],))
    certificates = cursor.fetchall()
    
    cursor.execute("""
        SELECT * FROM Course 
        WHERE course_id NOT IN (SELECT course_id FROM Enrollment WHERE user_id = %s)
    """, (session['user_id'],))
    available_courses = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('student_dashboard.html', 
                          user_name=session['name'], 
                          enrollments=enrollments,
                          certificates=certificates,
                          available_courses=available_courses)

@app.route('/request_enrollment', methods=['POST'])
def request_enrollment():
    if 'user_id' not in session or session.get('role') != 'STUDENT':
        return redirect(url_for('login'))
        
    course_id = request.form.get('course_id')
    if course_id:
        conn = get_connection()
        cursor = conn.cursor()
        try:
            cursor.execute("INSERT INTO Enrollment (user_id, course_id, enrolled_date, status) VALUES (%s, %s, CURDATE(), 'PENDING')", (session['user_id'], course_id))
            conn.commit()
        except mysql.connector.Error:
            pass
        finally:
            cursor.close()
            conn.close()
    return redirect(url_for('dashboard'))

@app.route('/course/<int:course_id>')
def view_course(course_id):
    if 'user_id' not in session or session.get('role') != 'STUDENT':
        return redirect(url_for('login'))

    enrollment_status = get_enrollment_status(session['user_id'], course_id)
    if enrollment_status != 'ACTIVE':
        if enrollment_status == 'PENDING':
            return redirect(url_for('dashboard', error="Your course request is still pending admin approval."))
        return redirect(url_for('dashboard', error="You do not have access to this course."))
        
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT title, course_id FROM Course WHERE course_id = %s", (course_id,))
    course = cursor.fetchone()
    
    cursor.execute("""
        SELECT m.*, v.video_id, v.video_url, v.duration_minutes, p.status as project_status, vp.completed as video_completed
        FROM Module m
        LEFT JOIN Video v ON m.module_id = v.module_id
        LEFT JOIN Video_Progress vp ON v.video_id = vp.video_id AND vp.user_id = %s
        LEFT JOIN Project_Submission p ON m.module_id = p.module_id AND p.user_id = %s
        WHERE m.course_id = %s
        ORDER BY m.module_order ASC
    """, (session['user_id'], session['user_id'], course_id))
    modules = cursor.fetchall()
    
    for mod in modules:
        if mod.get('video_url'):
            url = mod['video_url']
            if 'watch?v=' in url:
                video_id = url.split('watch?v=')[1].split('&')[0]
                mod['embed_url'] = f"https://www.youtube.com/embed/{video_id}"
            elif 'youtu.be/' in url:
                video_id = url.split('youtu.be/')[1].split('?')[0]
                mod['embed_url'] = f"https://www.youtube.com/embed/{video_id}"
            else:
                mod['embed_url'] = url
    
    cursor.close()
    conn.close()
    
    error_msg = request.args.get('error')
    success_msg = request.args.get('success')
    
    return render_template('student_course.html', course=course, modules=modules, error_msg=error_msg, success_msg=success_msg)

@app.route('/mark_complete', methods=['POST'])
def mark_complete():
    if 'user_id' not in session or session.get('role') != 'STUDENT': return redirect(url_for('login'))
    
    course_id = request.form.get('course_id')
    video_id = request.form.get('video_id')

    if get_enrollment_status(session['user_id'], course_id) != 'ACTIVE':
        return redirect(url_for('dashboard', error="You cannot access this course until your enrollment is approved."))
    
    if course_id and video_id:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        # Mark video complete
        cursor.execute("INSERT INTO Video_Progress (user_id, video_id, completed, completed_at) VALUES (%s, %s, 1, NOW()) ON DUPLICATE KEY UPDATE completed=1", (session['user_id'], video_id))
        
        # Calculate new progress percentage
        cursor.execute("SELECT COUNT(*) as total FROM Module m LEFT JOIN Video v ON m.module_id = v.module_id WHERE m.course_id = %s AND m.module_type = 'VIDEO'", (course_id,))
        total_videos = cursor.fetchone()['total']
        
        cursor.execute("SELECT COUNT(*) as completed FROM Video_Progress vp JOIN Video v ON vp.video_id = v.video_id JOIN Module m ON v.module_id = m.module_id WHERE m.course_id = %s AND vp.user_id = %s AND vp.completed = 1", (course_id, session['user_id']))
        completed_videos = cursor.fetchone()['completed']
        
        if total_videos > 0:
            percentage = int((completed_videos / total_videos) * 100)
            cursor.execute("UPDATE Enrollment SET progress_percentage = %s WHERE user_id = %s AND course_id = %s", (percentage, session['user_id'], course_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
    return redirect(url_for('view_course', course_id=course_id, success="Video marked as complete!"))

@app.route('/submit_project', methods=['POST'])
def submit_project():
    if 'user_id' not in session or session.get('role') != 'STUDENT':
        return redirect(url_for('login'))
        
    course_id = request.form.get('course_id')
    module_id = request.form.get('module_id')
    github_link = request.form.get('github_link')

    if get_enrollment_status(session['user_id'], course_id) != 'ACTIVE':
        return redirect(url_for('dashboard', error="You cannot submit projects until your enrollment is approved."))
    
    if module_id and github_link:
        conn = get_connection()
        cursor = conn.cursor()
        try:
            cursor.execute("SELECT submission_id FROM Project_Submission WHERE user_id = %s AND module_id = %s", (session['user_id'], module_id))
            if cursor.fetchone():
                return redirect(url_for('view_course', course_id=course_id, error="You have already submitted a project for this module."))
                
            cursor.execute("""
                INSERT INTO Project_Submission (user_id, module_id, github_link, submitted_date, status)
                VALUES (%s, %s, %s, CURDATE(), 'PENDING')
            """, (session['user_id'], module_id, github_link))
            conn.commit()
            return redirect(url_for('view_course', course_id=course_id, success="Project submitted successfully! Waiting for Admin approval."))
        except mysql.connector.Error as err:
            return redirect(url_for('view_course', course_id=course_id, error=str(err)))
        finally:
            cursor.close()
            conn.close()
    return redirect(url_for('dashboard'))

@app.route('/quiz/<int:module_id>')
def attend_quiz(module_id):
    if 'user_id' not in session or session.get('role') != 'STUDENT':
        return redirect(url_for('login'))

    course_id = get_course_id_for_module(module_id)
    if not course_id:
        return "Quiz not found", 404
    if get_enrollment_status(session['user_id'], course_id) != 'ACTIVE':
        return redirect(url_for('dashboard', error="You cannot access quizzes until your enrollment is approved."))
        
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("""
        SELECT q.quiz_id, q.quiz_title, q.pass_marks, m.course_id
        FROM Quiz q
        JOIN Module m ON q.module_id = m.module_id
        WHERE q.module_id = %s
    """, (module_id,))
    quiz = cursor.fetchone()
    
    if not quiz:
        cursor.close()
        conn.close()
        return "Quiz not found", 404
        
    cursor.execute("SELECT * FROM Question WHERE quiz_id = %s", (quiz['quiz_id'],))
    questions = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('student_quiz.html', quiz=quiz, questions=questions, course_id=quiz['course_id'])

@app.route('/submit_quiz', methods=['POST'])
def submit_quiz():
    if 'user_id' not in session or session.get('role') != 'STUDENT':
        return redirect(url_for('login'))
        
    quiz_id = request.form.get('quiz_id')
    course_id = request.form.get('course_id')

    if get_enrollment_status(session['user_id'], course_id) != 'ACTIVE':
        return redirect(url_for('dashboard', error="You cannot submit quizzes until your enrollment is approved."))
    
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM Question WHERE quiz_id = %s", (quiz_id,))
    questions = cursor.fetchall()
    
    score = 0
    total = len(questions)
    
    cursor.execute("INSERT INTO Quiz_Attempt (user_id, quiz_id, total_questions) VALUES (%s, %s, %s)",
                  (session['user_id'], quiz_id, total))
    attempt_id = cursor.lastrowid
    
    for q in questions:
        q_id = str(q['question_id'])
        selected = request.form.get(f'q_{q_id}')
        is_correct = False
        if selected == q['correct_option']:
            score += 1
            is_correct = True
            
        if selected:
            cursor.execute("""
                INSERT INTO Quiz_Response (attempt_id, question_id, selected_option, is_correct)
                VALUES (%s, %s, %s, %s)
            """, (attempt_id, q['question_id'], selected, is_correct))
            
    cursor.execute("UPDATE Quiz_Attempt SET score = %s WHERE attempt_id = %s", (score, attempt_id))
    
    cursor.execute("SELECT pass_marks FROM Quiz WHERE quiz_id = %s", (quiz_id,))
    pass_marks = cursor.fetchone()['pass_marks']
    
    conn.commit()
    cursor.close()
    conn.close()
    
    if score >= pass_marks:
        return redirect(url_for('view_course', course_id=course_id, success=f"Congratulations! You passed the quiz with {score}/{total}."))
    else:
        return redirect(url_for('view_course', course_id=course_id, error=f"You scored {score}/{total}. You need {pass_marks} to pass. Please try again."))

if __name__ == '__main__':
    app.run(debug=True, port=5000)
