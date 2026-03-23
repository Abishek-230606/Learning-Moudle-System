import mysql.connector
conn = mysql.connector.connect(host='localhost', user='root', password='Sathishdhana#23', database='lms_db')
cursor = conn.cursor()
cursor.execute("ALTER TABLE Enrollment MODIFY status ENUM('PENDING', 'ACTIVE', 'COMPLETED') DEFAULT 'ACTIVE'")
conn.commit()
print("Success")
