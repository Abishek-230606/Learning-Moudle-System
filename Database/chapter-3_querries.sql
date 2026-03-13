USE lms_db;

-- Question 1 : Ensure that a student cannot enroll in the same course twice.

ALTER TABLE Enrollment
ADD CONSTRAINT unique_enrollment
UNIQUE(user_id, course_id);

-- QUESTION 2 : Ensure that video progress percentage cannot exceed 100

ALTER TABLE Video_Progress
ADD CONSTRAINT check_percentage
CHECK (watched_percentage BETWEEN 0 AND 100);

-- Question -3 Ensure quiz scores cannot be negative.

ALTER TABLE Quiz_Attempt
ADD CONSTRAINT check_score
CHECK (score >= 0);

-- question 4 Find total number of students enrolled in each course.
SELECT course_id, COUNT(user_id) AS total_students
FROM Enrollment
GROUP BY course_id;

-- question 5 Find average quiz score for each quiz.

SELECT quiz_id, AVG(score) AS average_score
FROM Quiz_Attempt
GROUP BY quiz_id;

-- question 6 Find maximum score obtained by students in quizzes.

SELECT MAX(score) AS highest_score
FROM Quiz_Attempt;

-- question - Find users enrolled in both AI & Cyber Security courses.
SELECT user_id
FROM Enrollment
WHERE course_id = 1
INTERSECT
SELECT user_id
FROM Enrollment
WHERE course_id = 2;

-- QUESTION Find students enrolled in AI but not in DSA.

SELECT user_id
FROM Enrollment
WHERE course_id = 1
EXCEPT
SELECT user_id
FROM Enrollment
WHERE course_id = 3;


-- List students enrolled in either Web Development or DBMS.
SELECT user_id FROM Enrollment WHERE course_id = 4
UNION
SELECT user_id FROM Enrollment WHERE course_id = 5;

-- question Find students who scored above the average score.

SELECT user_id, score
FROM Quiz_Attempt
WHERE score >
(
SELECT AVG(score)
FROM Quiz_Attempt
);


-- Find courses with maximum duration.
SELECT title
FROM Course
WHERE duration =
(
SELECT MAX(duration)
FROM Course
);

-- question  Find students enrolled in more than one course.

SELECT user_id
FROM Enrollment
GROUP BY user_id
HAVING COUNT(course_id) >
(
SELECT 1
);

-- List student names with the courses they enrolled in.

SELECT U.name, C.title
FROM User U
JOIN Enrollment E ON U.user_id = E.user_id
JOIN Course C ON E.course_id = C.course_id;
 USE lms_db;

-- Display lessons with their module names.

SELECT L.video_title, M.module_title
FROM Lesson L
JOIN Module M ON L.module_id = M.module_id;

-- Find students and their quiz scores.

SELECT U.name, Q.score
FROM User U
JOIN Quiz_Attempt Q
ON U.user_id = Q.user_id;

CREATE VIEW student_course_view AS
SELECT U.name, C.title
FROM User U
JOIN Enrollment E ON U.user_id = E.user_id
JOIN Course C ON E.course_id = C.course_id;

-- Retrieve data from the view.

SELECT * FROM student_course_view;

-- Create a view for quiz results.

CREATE VIEW quiz_result_view AS
SELECT U.name, Q.score
FROM User U
JOIN Quiz_Attempt Q
ON U.user_id = Q.user_id;

-- Prevent quiz score above 100.

DELIMITER $$

CREATE TRIGGER check_score_limit
BEFORE INSERT ON Quiz_Attempt
FOR EACH ROW
BEGIN
IF NEW.score > 100 THEN
SET NEW.score = 100;
END IF;
END $$

DELIMITER ;

-- Automatically update course completion when assignment submitted.

DELIMITER $$

CREATE TRIGGER update_completion
AFTER INSERT ON Project_Submission
FOR EACH ROW
BEGIN
UPDATE Enrollment
SET status = 'COMPLETED'
WHERE user_id = NEW.user_id;
END $$

DELIMITER ;

-- List all users enrolled in courses.
DELIMITER $$
CREATE PROCEDURE list_students()
BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE uname VARCHAR(255);
DECLARE cur CURSOR FOR
SELECT name FROM User;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
OPEN cur;
read_loop: LOOP
FETCH cur INTO uname;
IF done THEN
LEAVE read_loop;
END IF;
SELECT uname;
END LOOP;
CLOSE cur;
END $$
DELIMITER ;

-- Execute the cursor procedure.

CALL list_students();

-- Cursor to display courses sequentially.
DELIMITER $$
CREATE PROCEDURE course_list()
BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE cname VARCHAR(255);
DECLARE course_cursor CURSOR FOR
SELECT title FROM Course;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
OPEN course_cursor;
course_loop: LOOP
FETCH course_cursor INTO cname;
IF done THEN
LEAVE course_loop;
END IF;
SELECT cname;
END LOOP;
CLOSE course_cursor;
END $$
DELIMITER ;
