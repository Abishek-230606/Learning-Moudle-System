USE lms_db;

INSERT INTO User (name,email,password)
VALUES
('Arjun Kumar','arjun@gmail.com','arjun'),
('Priya Sharma','priya@gmail.com','priya'),
('Rahul Verma','rahul@gmail.com','rahul'),
('Sneha Iyer','sneha@gmail.com','sneha'),
('Karthik R','karthik@gmail.com','karthik'),
('Neha Patel','neha@gmail.com','neha'),
('Rohit Meena','rohit@gmail.com','rohit'),
('Anjali Das','anjali@gmail.com','anjali'),
('Vikram Singh','vikram@gmail.com','vikram'),
('Ravi Kumar','ravi@gmail.com','ravi'),
('Meera Nair','meera@gmail.com','meera'),
('Ajay Sharma','ajay@gmail.com','ajay');


INSERT INTO User (name,email,password,role)
VALUES
('System Admin','admin@lms.com','admin','ADMIN');

SELECT user_id,name FROM User;


-- course 

INSERT INTO Course (title,description,duration,level)
VALUES
('C++ Programming',
'Learn C++ syntax, loops, functions and build a mini project',
40,'Beginner'),

('Database Management Systems',
'Learn ER model, SQL, normalization and transactions',
45,'Intermediate'),

('Frontend Web Development',
'HTML CSS JavaScript and responsive design',
50,'Beginner'),

('Data Structures',
'Arrays linked lists stacks queues trees graphs',
55,'Intermediate'),

('Artificial Intelligence & Machine Learning',
'ML concepts preprocessing supervised learning evaluation',
60,'Intermediate');

-- moudle 

INSERT INTO Module (course_id,module_title,module_order,module_type)
VALUES
(1,'C++ Basics',1,'VIDEO'),
(1,'Variables and Data Types',2,'VIDEO'),
(1,'Control Statements',3,'VIDEO'),
(1,'Functions and Arrays',4,'VIDEO'),
(1,'Mini Project C++',5,'PROJECT'),
(1,'Final Quiz C++',6,'QUIZ'),

(2,'Introduction to DBMS',1,'VIDEO'),
(2,'ER Model',2,'VIDEO'),
(2,'SQL Basics',3,'VIDEO'),
(2,'Normalization',4,'VIDEO'),
(2,'Database Design Project',5,'PROJECT'),
(2,'Final Quiz DBMS',6,'QUIZ');


-- video

INSERT INTO Video (module_id,video_title,video_url,duration_minutes)
VALUES
(1,'C++ Introduction','https://youtu.be/s0g4ty29Xgg',20),
(2,'Variables in C++','https://youtu.be/fZbSl58orNs',18),
(3,'Control Statements','https://youtu.be/9-BjXs1vMSc',22),
(4,'Functions and Arrays','https://youtu.be/OgosiMQPGVA',25),

(7,'What is DBMS','https://youtu.be/HXV3zeQKqGY',20),
(8,'ER Model Explained','https://youtu.be/FQm_wpA9BR0',18),
(9,'SQL Basics','https://youtu.be/7S_tz1z_5bA',22),
(10,'Normalization','https://youtu.be/UrYLYV7WS_8',25);




-- enrollment 

INSERT INTO Enrollment (user_id,course_id,enrolled_date,status)
VALUES
(2,1,CURDATE(),'ACTIVE'),
(3,1,CURDATE(),'ACTIVE'),
(4,2,CURDATE(),'ACTIVE'),
(5,2,CURDATE(),'ACTIVE'),
(6,3,CURDATE(),'ACTIVE'),
(7,3,CURDATE(),'ACTIVE'),
(8,4,CURDATE(),'ACTIVE'),
(9,5,CURDATE(),'ACTIVE'),
(10,1,CURDATE(),'ACTIVE'),
(11,2,CURDATE(),'ACTIVE'),
(12,3,CURDATE(),'ACTIVE');


-- vedio progress 

INSERT INTO Video_Progress (user_id,video_id,completed,completed_at)
VALUES
(2,1,TRUE,NOW()),
(2,2,TRUE,NOW()),
(2,3,FALSE,NULL),

(3,1,TRUE,NOW()),
(3,2,TRUE,NOW()),
(3,3,TRUE,NOW()),

(4,5,TRUE,NOW()),
(4,6,FALSE,NULL),

(5,5,TRUE,NOW()),
(5,6,TRUE,NOW());

INSERT INTO Module (course_id,module_title,module_order,module_type)
VALUES
(3,'HTML Basics',1,'VIDEO'),
(3,'CSS Fundamentals',2,'VIDEO'),
(3,'JavaScript Basics',3,'VIDEO'),
(3,'Responsive Design',4,'VIDEO'),
(3,'Frontend Project',5,'PROJECT'),
(3,'Final Quiz Frontend',6,'QUIZ'),

(4,'Arrays',1,'VIDEO'),
(4,'Linked Lists',2,'VIDEO'),
(4,'Stacks and Queues',3,'VIDEO'),
(4,'Trees',4,'VIDEO'),
(4,'Data Structures Project',5,'PROJECT'),
(4,'Final Quiz Data Structures',6,'QUIZ'),

(5,'Intro to AI',1,'VIDEO'),
(5,'Machine Learning Basics',2,'VIDEO'),
(5,'Data Preprocessing',3,'VIDEO'),
(5,'Model Evaluation',4,'VIDEO'),
(5,'ML Project',5,'PROJECT'),
(5,'Final Quiz AI',6,'QUIZ');

INSERT INTO Quiz (module_id,quiz_title)
VALUES
(6,'C++ Final Quiz'),
(12,'DBMS Final Quiz');

SELECT module_id,module_title,module_type
FROM Module
WHERE module_type='QUIZ';

SELECT module_title, COUNT(*)
FROM Module
GROUP BY module_title
HAVING COUNT(*) > 1;

SELECT course_id, COUNT(*) AS total_modules
FROM Module
GROUP BY course_id;

SELECT module_id,module_title
FROM Module
WHERE module_type='QUIZ';

INSERT INTO Quiz (module_id,quiz_title)
VALUES
(6,'C++ Final Quiz'),
(12,'DBMS Final Quiz'),
(30,'Frontend Final Quiz'),
(36,'Data Structures Final Quiz'),
(42,'AI & ML Final Quiz');

-- questions 

INSERT INTO Question
(quiz_id,question_text,option_a,option_b,option_c,option_d,correct_option)
VALUES

(9,'Which symbol ends a C++ statement?','Colon','Semicolon','Dot','Comma','B'),
(9,'Which data type stores whole numbers?','int','float','char','double','A'),
(9,'Which keyword defines a function?','void','define','function','func','A'),

(10,'What does DBMS stand for?','Database Main System','Database Management System','Data Backup System','Data Managing Service','B'),
(10,'Which SQL command creates a table?','INSERT','CREATE','UPDATE','SELECT','B'),
(10,'Primary key must be?','Duplicate','Null','Unique','Optional','C'),

(13,'HTML stands for?','Hyper Text Markup Language','High Tech Machine Learning','Hyperlinks Text Module Language','Home Tool Markup Language','A'),
(13,'CSS is used for?','Logic','Styling','Database','Security','B'),
(13,'JavaScript runs on?','Browser','Database','Server only','Compiler','A'),

(14,'Stack follows which order?','FIFO','LIFO','Random','Priority','B'),
(14,'Queue follows?','LIFO','FIFO','Tree','Graph','B'),
(14,'Binary search works on?','Sorted data','Unsorted data','Random data','None','A'),

(15,'AI stands for?','Artificial Intelligence','Automated Internet','Advanced Interface','Applied Informatics','A'),
(15,'Machine Learning is subset of?','DBMS','AI','Networking','OS','B'),
(15,'Accuracy measures?','Speed','Model performance','Memory','Storage','B');


SELECT quiz_id, quiz_title
FROM Quiz;

INSERT INTO Quiz_Attempt (user_id,quiz_id,score,total_questions)
VALUES
(2,9,2,3),
(3,10,3,3),
(4,13,2,3),
(5,14,1,3),
(6,15,3,3);

SELECT module_id,module_title
FROM Module
WHERE module_type='PROJECT';

INSERT INTO Project_Submission
(user_id,module_id,github_link,submitted_date,status)
VALUES
(2,5,'https://github.com/arjun/cpp-project','2026-03-10','APPROVED'),
(3,11,'https://github.com/priya/dbms-project','2026-03-11','PENDING'),
(4,29,'https://github.com/rahul/frontend-project','2026-03-11','APPROVED'),
(5,35,'https://github.com/sneha/dsa-project','2026-03-12','PENDING'),
(6,41,'https://github.com/karthik/ml-project','2026-03-12','APPROVED');

DESCRIBE Certificate;

INSERT INTO Certificate
(user_id,course_id,certificate_code)
VALUES
(2,1,'CERT-CPP-001'),
(4,3,'CERT-FE-002'),
(6,5,'CERT-AI-003');


SELECT
User.name,
Course.title,
Certificate.certificate_code,
Certificate.issue_date
FROM Certificate
JOIN User ON Certificate.user_id = User.user_id
JOIN Course ON Certificate.course_id = Course.course_id;

-- insertion of remaining videos

INSERT INTO Video (module_id,video_title,video_url,duration_minutes)
VALUES
-- Frontend course
(25,'HTML Basics','https://www.youtube.com/watch?v=pQN-pnXPaVg',20),
(26,'CSS Fundamentals','https://www.youtube.com/watch?v=OXGznpKZ_sA',18),
(27,'JavaScript Basics','https://www.youtube.com/watch?v=W6NZfCO5SIk',22),
(28,'Responsive Design','https://www.youtube.com/watch?v=srvUrASNj0s',25),

-- Data Structures course
(31,'Arrays Explained','https://www.youtube.com/watch?v=6w3L4Y1PI5M',20),
(32,'Linked Lists','https://www.youtube.com/watch?v=6w3L4Y1PI5M',18),
(33,'Stacks and Queues','https://www.youtube.com/watch?v=wjI1WNcIntg',22),
(34,'Trees Introduction','https://www.youtube.com/watch?v=oSWT8gNZ5oA',25),

-- AI ML course
(37,'Sorting & Searching Algorithms','https://www.youtube.com/watch?v=ZZuD6iUe3Pc',20),
(38,'What is AI & ML?','https://www.youtube.com/watch?v=ukzFI9rgwfU',18),
(39,'Data Preprocessing in ML','https://www.youtube.com/watch?v=0xVqLJe9_CY',22),
(40,'Supervised Learning Explained,Model Evaluation','https://www.youtube.com/watch?v=85dtiMz9tSo',25);

-- updating the video progress table 
INSERT IGNORE INTO Video_Progress
(user_id, video_id, completed, completed_at)
SELECT
u.user_id,
v.video_id,
IF(RAND() > 0.4, TRUE, FALSE),
NOW()
FROM User u
JOIN Video v
WHERE u.role='STUDENT'
LIMIT 60;
