USE lms_db;

CREATE TABLE lms_raw (
    user_id INT,
    user_name VARCHAR(100),
    course_id INT,
    course_title VARCHAR(100),
    module_title VARCHAR(100),
    video_title VARCHAR(100),
    video_url VARCHAR(100)
);

INSERT INTO lms_raw VALUES
(1,'Abishek',1,'DBMS','Intro,SQL','Video1,Video2','url1,url2'),
(1,'Abishek',1,'DBMS','Intro,SQL','Video1,Video2','url1,url2'),
(2,'Jisvin',2,'AI','Basics,ML','VideoA,VideoB','urlA,urlB'),
(2,'Jisvin',3,'DSA','Arrays,Trees','VideoX,VideoY','urlX,urlY'),
(3,'Raj',3,'DSA','Arrays,Trees','VideoX,VideoY','urlX,urlY'),
(3,'Raj',4,'Web Dev','HTML,CSS','VideoH,VideoC','urlH,urlC');

SELECT * FROM lms_raw;
-- 1nf atomic values

CREATE TABLE lms_1nf AS

SELECT user_id,user_name,course_id,course_title,
SUBSTRING_INDEX(module_title, ',', 1) AS module_title,
SUBSTRING_INDEX(video_title, ',', 1) AS video_title,
SUBSTRING_INDEX(video_url, ',', 1) AS video_url
FROM lms_raw

UNION ALL

SELECT user_id,user_name,course_id,course_title,
SUBSTRING_INDEX(module_title, ',', -1),
SUBSTRING_INDEX(video_title, ',', -1),
SUBSTRING_INDEX(video_url, ',', -1)
FROM lms_raw;

SELECT * FROM lms_1nf;

-- 2NF PARTIAL DEPENDENCY

CREATE TABLE lms_2nf_enrollment AS
SELECT DISTINCT user_id, course_id FROM lms_1nf;

CREATE TABLE lms_2nf_course AS
SELECT DISTINCT course_id, course_title FROM lms_1nf;

CREATE TABLE lms_2nf_video AS
SELECT DISTINCT course_id,module_title,video_title,video_url FROM lms_1nf;

-- 3NF TRANSTITIVE DEPENDENCY

CREATE TABLE lms_3nf_student AS
SELECT DISTINCT user_id, user_name FROM lms_1nf;

CREATE TABLE lms_3nf_enrollment AS
SELECT DISTINCT user_id, course_id FROM lms_1nf;

CREATE TABLE lms_3nf_course AS
SELECT DISTINCT course_id, course_title FROM lms_1nf;

CREATE TABLE lms_3nf_video AS
SELECT DISTINCT course_id,module_title,video_title,video_url FROM lms_1nf;

-- BCNF 

CREATE TABLE lms_bcnf_video AS
SELECT DISTINCT video_title, video_url FROM lms_1nf;

CREATE TABLE lms_bcnf_mapping AS
SELECT DISTINCT course_id, module_title, video_title FROM lms_1nf;

-- 4NF MULTI VALUED DEPENDENCY 

CREATE TABLE lms_4nf_course_module AS
SELECT DISTINCT course_id, module_title FROM lms_1nf;

CREATE TABLE lms_4nf_module_video AS
SELECT DISTINCT module_title, video_title FROM lms_1nf;

-- 5NF JOIN DEPENDENCY 

-- Student
CREATE TABLE lms_5nf_student AS
SELECT DISTINCT user_id, user_name FROM lms_1nf;

-- Course
CREATE TABLE lms_5nf_course AS
SELECT DISTINCT course_id, course_title FROM lms_1nf;

-- Enrollment
CREATE TABLE lms_5nf_enrollment AS
SELECT DISTINCT user_id, course_id FROM lms_1nf;

-- Course ↔ Module
CREATE TABLE lms_5nf_course_module AS
SELECT DISTINCT course_id, module_title FROM lms_1nf;

-- Module ↔ Video
CREATE TABLE lms_5nf_module_video AS
SELECT DISTINCT module_title, video_title FROM lms_1nf;

-- Video Details
CREATE TABLE lms_5nf_video AS
SELECT DISTINCT video_title, video_url FROM lms_1nf;


-- SHOWING REPECTIVE TABLES

SELECT * FROM lms_raw;
SELECT * FROM lms_1nf;

SELECT * FROM lms_2nf_enrollment;
SELECT * FROM lms_2nf_course;
SELECT * FROM lms_2nf_video;

SELECT * FROM lms_3nf_student;
SELECT * FROM lms_3nf_enrollment;
SELECT * FROM lms_3nf_course;
SELECT * FROM lms_3nf_video;

SELECT * FROM lms_bcnf_video;
SELECT * FROM lms_bcnf_mapping;

SELECT * FROM lms_4nf_course_module;
SELECT * FROM lms_4nf_module_video;

SELECT * FROM lms_5nf_student;
SELECT * FROM lms_5nf_course;
SELECT * FROM lms_5nf_enrollment;
SELECT * FROM lms_5nf_course_module;
SELECT * FROM lms_5nf_module_video;
SELECT * FROM lms_5nf_video;
