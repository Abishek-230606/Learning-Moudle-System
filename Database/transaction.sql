-- Transactions in lms 

-- TRANSACTION 1 — STUDENT ENROLLMENT + PROGRESS INIT


START TRANSACTION;

-- Step 1: Enroll student
INSERT INTO ENROLLMENT (user_id, course_id, enrolled_date, status)
VALUES (1, 2, CURDATE(), 'ACTIVE');

SAVEPOINT after_enrollment;

-- Step 2: Initialize progress
INSERT INTO VIDEO_PROGRESS (user_id, lesson_id, watched_percentage, completed)
VALUES (1, 1, 0, FALSE);

-- Suppose error occurs → rollback
ROLLBACK TO after_enrollment;

-- Safe re-insert
INSERT INTO VIDEO_PROGRESS (user_id, lesson_id, watched_percentage, completed)
VALUES (1, 2, 0, FALSE);

COMMIT;

-- Tansaction-2 VIDEO COMPLETION + COURSE STATUS UPDATE

START TRANSACTION;

UPDATE VIDEO_PROGRESS
SET watched_percentage = 100, completed = TRUE
WHERE user_id = 1 AND lesson_id = 2;

SAVEPOINT after_video;

UPDATE ENROLLMENT
SET status = 'COMPLETED'
WHERE user_id = 1 AND course_id = 2;

COMMIT;

-- transaction-3 QUIZ ATTEMPT + SCORE RECORD

	START TRANSACTION;

INSERT INTO QUIZ_ATTEMPT (user_id, quiz_id, score, attempt_date)
VALUES (1, 1, 85, CURDATE());

SAVEPOINT after_attempt;

-- Suppose invalid score update
UPDATE QUIZ_ATTEMPT
SET score = -10
WHERE attempt_id = 1;

ROLLBACK TO after_attempt;

-- Correct update
UPDATE QUIZ_ATTEMPT
SET score = 85
WHERE attempt_id = 1;

COMMIT;

-- TRANSACTION 4 — PROJECT SUBMISSION + CERTIFICATE

START TRANSACTION;

INSERT INTO PROJECT_SUBMISSION (user_id, assignment_id, github_link, submitted_date)
VALUES (1, 1, 'https://github.com/Abishek-230606', CURDATE());

SAVEPOINT after_submission;

INSERT INTO CERTIFICATE (user_id, course_id, issued_date, certificate_code)
VALUES (1, 2, CURDATE(), 'CERT123');

COMMIT;

-- TRANSACTION 5 — COURSE UPDATE WITH ROLLBACK

START TRANSACTION;

UPDATE COURSE
SET duration = 100
WHERE course_id = 1;

SAVEPOINT after_update;

-- Mistake
UPDATE COURSE
SET duration = -50
WHERE course_id = 1;

ROLLBACK TO after_update;

COMMIT;