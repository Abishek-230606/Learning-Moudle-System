DROP DATABASE IF EXISTS lms_db;

CREATE DATABASE lms_db;

USE lms_db;

CREATE TABLE User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('STUDENT','ADMIN') DEFAULT 'STUDENT',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- course table 

CREATE TABLE Course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    duration INT NOT NULL,
    level VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- moudle table
CREATE TABLE Module (
    module_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    module_title VARCHAR(255) NOT NULL,
    module_order INT NOT NULL,
    module_type ENUM('VIDEO','PROJECT','QUIZ') NOT NULL,
    UNIQUE(course_id,module_order),
    FOREIGN KEY(course_id) REFERENCES Course(course_id)
);

-- vedio table 
CREATE TABLE Video (
    video_id INT AUTO_INCREMENT PRIMARY KEY,
    module_id INT NOT NULL,
    video_title VARCHAR(255) NOT NULL,
    video_url VARCHAR(500) NOT NULL,
    duration_minutes INT,
    FOREIGN KEY(module_id) REFERENCES Module(module_id)
);

-- enrollment table 

CREATE TABLE Enrollment (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    enrolled_date DATE NOT NULL,
    status ENUM('ACTIVE','COMPLETED') DEFAULT 'ACTIVE',
    progress_percentage INT DEFAULT 0,
    UNIQUE(user_id,course_id),
    FOREIGN KEY(user_id) REFERENCES User(user_id),
    FOREIGN KEY(course_id) REFERENCES Course(course_id)
);

-- video progress 

CREATE TABLE Video_Progress (
    progress_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    video_id INT NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at DATETIME,
    UNIQUE(user_id,video_id),
    FOREIGN KEY(user_id) REFERENCES User(user_id),
    FOREIGN KEY(video_id) REFERENCES Video(video_id)
);

-- quiz table 

CREATE TABLE Quiz (
    quiz_id INT AUTO_INCREMENT PRIMARY KEY,
    module_id INT NOT NULL,
    quiz_title VARCHAR(255) NOT NULL,
    pass_marks INT DEFAULT 2,
    FOREIGN KEY(module_id) REFERENCES Module(module_id)
);

-- question table 

CREATE TABLE Question (
    question_id INT AUTO_INCREMENT PRIMARY KEY,
    quiz_id INT NOT NULL,
    question_text TEXT NOT NULL,
    option_a VARCHAR(255) NOT NULL,
    option_b VARCHAR(255) NOT NULL,
    option_c VARCHAR(255) NOT NULL,
    option_d VARCHAR(255) NOT NULL,
    correct_option CHAR(1) NOT NULL,
    FOREIGN KEY(quiz_id) REFERENCES Quiz(quiz_id)
);

-- quiz attempt table 

CREATE TABLE Quiz_Attempt (
    attempt_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    quiz_id INT NOT NULL,
    score INT DEFAULT 0,
    total_questions INT NOT NULL,
    attempt_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES User(user_id),
    FOREIGN KEY(quiz_id) REFERENCES Quiz(quiz_id)
);

-- quiz response 
CREATE TABLE Quiz_Response (
    response_id INT AUTO_INCREMENT PRIMARY KEY,
    attempt_id INT NOT NULL,
    question_id INT NOT NULL,
    selected_option CHAR(1) NOT NULL,
    is_correct BOOLEAN,
    FOREIGN KEY(attempt_id) REFERENCES Quiz_Attempt(attempt_id),
    FOREIGN KEY(question_id) REFERENCES Question(question_id)
);

-- project subbmission 

CREATE TABLE Project_Submission (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    module_id INT NOT NULL,
    github_link VARCHAR(500) NOT NULL,
    submitted_date DATE NOT NULL,
    status ENUM('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
    FOREIGN KEY(user_id) REFERENCES User(user_id),
    FOREIGN KEY(module_id) REFERENCES Module(module_id)
);

-- certificate 

CREATE TABLE Certificate (
    certificate_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    issue_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    certificate_code VARCHAR(100) UNIQUE NOT NULL,
    UNIQUE(user_id,course_id),
    FOREIGN KEY(user_id) REFERENCES User(user_id),
    FOREIGN KEY(course_id) REFERENCES Course(course_id)
);

SHOW TABLES;

ALTER TABLE Quiz
ADD CONSTRAINT unique_module_quiz
UNIQUE(module_id);

ALTER TABLE Project_Submission
ADD approved_by INT NULL,
ADD approval_date DATETIME NULL;

ALTER TABLE Project_Submission
ADD CONSTRAINT fk_project_admin
FOREIGN KEY (approved_by)
REFERENCES User(user_id);

ALTER TABLE Video_Progress
ADD CONSTRAINT check_completed
CHECK (completed IN (0,1));


DESCRIBE Video_Progress;



-- Trigger option (cirtificates automattically treiggers)
DELIMITER $$

CREATE TRIGGER generate_certificate
AFTER UPDATE ON Project_Submission
FOR EACH ROW
BEGIN

IF NEW.status = 'APPROVED' AND OLD.status != 'APPROVED' THEN

INSERT INTO Certificate(user_id,course_id,certificate_code)
VALUES
(
NEW.user_id,
(SELECT course_id FROM Module WHERE module_id = NEW.module_id),
CONCAT('CERT-',NEW.user_id,'-',NEW.module_id)
);

END IF;

END$$

DELIMITER ;



 