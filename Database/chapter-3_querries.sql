USE lms_db;

-- Admin Dashboard page (qurries for that)

SELECT COUNT(*) AS total_students
FROM User
WHERE role='STUDENT';

-- Admin analytics(aggregate querry) - conncept (COUNT,GROUP BY,JOIN)

SELECT
Course.title,
COUNT(Enrollment.user_id) AS total_students
FROM Course
JOIN Enrollment
ON Course.course_id = Enrollment.course_id
GROUP BY Course.title;

-- Aggregate Query – Average Quiz Score - concept (Avg() , groupby)

SELECT
quiz_id,
AVG(score) AS average_score
FROM Quiz_Attempt
GROUP BY quiz_id;

-- Join Query – Course Content Page - (Student opens course)
-- concept - multi table join , count()

SELECT
Course.title,
Module.module_title,
Video.video_title
FROM Course
JOIN Module ON Course.course_id = Module.course_id
JOIN Video ON Module.module_id = Video.module_id;

SELECT
user_id,
COUNT(*) AS videos_tracked
FROM Video_Progress
GROUP BY user_id;

-- Sub querry 
-- Query 7 — Students Scoring Above Average

SELECT user_id,score
FROM Quiz_Attempt
WHERE score >
(
SELECT AVG(score)
FROM Quiz_Attempt
);

-- Query 8 — Courses With More Than One Student
-- concept sub querry,groupby , having

SELECT title
FROM Course
WHERE course_id IN
(
SELECT course_id
FROM Enrollment
GROUP BY course_id
HAVING COUNT(user_id) > 1
);


-- set operations
-- union

SELECT user_id
FROM Enrollment
WHERE course_id = 1

UNION

SELECT user_id
FROM Enrollment
WHERE course_id = 2;

