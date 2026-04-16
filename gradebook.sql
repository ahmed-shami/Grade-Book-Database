-- =============================================================
-- GRADEBOOK DATABASE
-- =============================================================
-- ER Design:
--   COURSE -> CATEGORY -> ASSIGNMENT
--   STUDENT -> ENROLLMENT <- COURSE
--   ENROLLMENT + ASSIGNMENT -> GRADE
-- =============================================================

-- Task 2: Create Tables
-- =============================================================

CREATE TABLE IF NOT EXISTS course (
    course_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    department    TEXT    NOT NULL,
    course_number TEXT    NOT NULL,
    course_name   TEXT    NOT NULL,
    semester      TEXT    NOT NULL CHECK (semester IN ('Spring','Summer','Fall')),
    year          INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS student (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name  TEXT NOT NULL,
    email      TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS enrollment (
    enrollment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id    INTEGER NOT NULL REFERENCES student(student_id),
    course_id     INTEGER NOT NULL REFERENCES course(course_id),
    UNIQUE (student_id, course_id)
);

-- Each category belongs to a course and carries a percentage weight.
-- The sum of weight_percent across all categories for a course must = 100.
CREATE TABLE IF NOT EXISTS category (
    category_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    course_id     INTEGER NOT NULL REFERENCES course(course_id),
    category_name TEXT    NOT NULL,
    weight_percent REAL   NOT NULL CHECK (weight_percent >= 0 AND weight_percent <= 100)
);

-- Each assignment belongs to a category.
-- Per-assignment weight = category.weight_percent / COUNT(assignments in category).
CREATE TABLE IF NOT EXISTS assignment (
    assignment_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id     INTEGER NOT NULL REFERENCES category(category_id),
    assignment_name TEXT    NOT NULL,
    max_points      REAL    NOT NULL DEFAULT 100.0
);

-- One grade row per (enrollment, assignment) pair.
CREATE TABLE IF NOT EXISTS grade (
    grade_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    enrollment_id INTEGER NOT NULL REFERENCES enrollment(enrollment_id),
    assignment_id INTEGER NOT NULL REFERENCES assignment(assignment_id),
    score         REAL    NOT NULL DEFAULT 0.0,
    UNIQUE (enrollment_id, assignment_id)
);


-- =============================================================
-- Task 3: Insert Sample Data
-- =============================================================

-- Courses
INSERT INTO course (department, course_number, course_name, semester, year) VALUES
    ('CS',   '101', 'Intro to Programming',    'Fall',   2024),
    ('MATH', '201', 'Calculus II',             'Spring', 2025),
    ('CS',   '305', 'Database Systems',        'Fall',   2024);

-- Students
INSERT INTO student (first_name, last_name, email) VALUES
    ('Alice',   'Anderson', 'aanderson@uni.edu'),
    ('Bob',     'Brown',    'bbrown@uni.edu'),
    ('Carol',   'Quinn',    'cquinn@uni.edu'),
    ('David',   'Qiu',      'dqiu@uni.edu'),
    ('Eve',     'Evans',    'eevans@uni.edu'),
    ('Frank',   'Foster',   'ffoster@uni.edu'),
    ('Grace',   'Garcia',   'ggarcia@uni.edu');

-- Enrollments (CS 101 and DB Systems have 5 students each; Calc II has 4)
INSERT INTO enrollment (student_id, course_id) VALUES
    -- CS 101 (course_id=1)
    (1,1),(2,1),(3,1),(4,1),(5,1),
    -- Calculus II (course_id=2)
    (1,2),(2,2),(6,2),(7,2),
    -- Database Systems (course_id=3)
    (3,3),(4,3),(5,3),(6,3),(7,3);

-- Categories for CS 101: 10% participation, 20% homework, 50% tests, 20% projects
INSERT INTO category (course_id, category_name, weight_percent) VALUES
    (1, 'Participation', 10),
    (1, 'Homework',      20),
    (1, 'Tests',         50),
    (1, 'Projects',      20);

-- Categories for Calculus II: 15% homework, 35% midterm, 50% final
INSERT INTO category (course_id, category_name, weight_percent) VALUES
    (2, 'Homework', 15),
    (2, 'Midterm',  35),
    (2, 'Final',    50);

-- Categories for Database Systems: 10% participation, 30% homework, 30% tests, 30% projects
INSERT INTO category (course_id, category_name, weight_percent) VALUES
    (3, 'Participation', 10),
    (3, 'Homework',      30),
    (3, 'Tests',         30),
    (3, 'Projects',      30);

-- Assignments for CS 101
--   Participation (cat 1): 1 assignment
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (1, 'Participation Overall', 100);
--   Homework (cat 2): 5 homeworks -> each worth 20/5 = 4%
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (2, 'HW1 - Hello World',    100),
    (2, 'HW2 - Loops',          100),
    (2, 'HW3 - Functions',      100),
    (2, 'HW4 - Lists',          100),
    (2, 'HW5 - File I/O',       100);
--   Tests (cat 3): 2 tests -> each worth 50/2 = 25%
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (3, 'Midterm Exam',         100),
    (3, 'Final Exam',           100);
--   Projects (cat 4): 2 projects -> each worth 20/2 = 10%
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (4, 'Project 1 - Calculator', 100),
    (4, 'Project 2 - Text Game',  100);

-- Assignments for Calculus II
--   Homework (cat 5): 3 homeworks
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (5, 'HW1 - Integrals',     100),
    (5, 'HW2 - Series',        100),
    (5, 'HW3 - Applications',  100);
--   Midterm (cat 6): 1 exam
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (6, 'Midterm Exam', 100);
--   Final (cat 7): 1 exam
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (7, 'Final Exam', 100);

-- Assignments for Database Systems
--   Participation (cat 8): 1 assignment
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (8, 'Participation Overall', 100);
--   Homework (cat 9): 4 homeworks
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (9, 'HW1 - SQL Basics',     100),
    (9, 'HW2 - Joins',          100),
    (9, 'HW3 - ER Design',      100),
    (9, 'HW4 - Normalization',  100);
--   Tests (cat 10): 2 tests
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (10, 'Midterm Exam', 100),
    (10, 'Final Exam',   100);
--   Projects (cat 11): 1 project
INSERT INTO assignment (category_id, assignment_name, max_points) VALUES
    (11, 'DB Design Project', 100);

-- Grades for CS 101 (enrollment_ids 1-5 = students 1-5 in course 1)
-- assignment_ids: 1=Part, 2-6=HW1-5, 7=Mid, 8=Final, 9=Proj1, 10=Proj2
INSERT INTO grade (enrollment_id, assignment_id, score) VALUES
    -- Alice (enrollment 1)
    (1,1,90),(1,2,88),(1,3,95),(1,4,100),(1,5,92),(1,6,87),
    (1,7,84),(1,8,91),(1,9,95),(1,10,88),
    -- Bob (enrollment 2)
    (2,1,75),(2,2,70),(2,3,80),(2,4,65),(2,5,78),(2,6,72),
    (2,7,68),(2,8,74),(2,9,80),(2,10,76),
    -- Carol Quinn (enrollment 3)
    (3,1,85),(3,2,92),(3,3,88),(3,4,90),(3,5,95),(3,6,89),
    (3,7,94),(3,8,97),(3,9,91),(3,10,93),
    -- David Qiu (enrollment 4)
    (4,1,60),(4,2,55),(4,3,70),(4,4,65),(4,5,58),(4,6,62),
    (4,7,72),(4,8,68),(4,9,75),(4,10,70),
    -- Eve (enrollment 5)
    (5,1,95),(5,2,98),(5,3,100),(5,4,96),(5,5,99),(5,6,97),
    (5,7,100),(5,8,99),(5,9,98),(5,10,100);

-- Grades for Calculus II (enrollment_ids 6-9 = students 1,2,6,7 in course 2)
-- assignment_ids: 11-13=HW1-3, 14=Mid, 15=Final
INSERT INTO grade (enrollment_id, assignment_id, score) VALUES
    (6,11,80),(6,12,85),(6,13,78),(6,14,82),(6,15,88),
    (7,11,55),(7,12,60),(7,13,50),(7,14,62),(7,15,58),
    (8,11,90),(8,12,95),(8,13,88),(8,14,91),(8,15,94),
    (9,11,72),(9,12,68),(9,13,75),(9,14,70),(9,15,73);

-- Grades for Database Systems (enrollment_ids 10-14 = students 3,4,5,6,7 in course 3)
-- assignment_ids: 16=Part, 17-20=HW1-4, 21=Mid, 22=Final, 23=Proj
INSERT INTO grade (enrollment_id, assignment_id, score) VALUES
    (10,16,88),(10,17,90),(10,18,85),(10,19,92),(10,20,87),
    (10,21,89),(10,22,91),(10,23,95),
    (11,16,65),(11,17,70),(11,18,60),(11,19,75),(11,20,68),
    (11,21,72),(11,22,70),(11,23,80),
    (12,16,95),(12,17,98),(12,18,100),(12,19,97),(12,20,99),
    (12,21,96),(12,22,98),(12,23,100),
    (13,16,78),(13,17,82),(13,18,79),(13,19,85),(13,20,80),
    (13,21,83),(13,22,86),(13,23,88),
    (14,16,55),(14,17,60),(14,18,58),(14,19,62),(14,20,57),
    (14,21,65),(14,22,63),(14,23,70);


-- =============================================================
-- Task 4: Average / Highest / Lowest score of an assignment
-- =============================================================

-- Example: stats for assignment_id = 7 (CS 101 Midterm Exam)
SELECT
    a.assignment_name,
    ROUND(AVG(g.score), 2) AS average_score,
    MAX(g.score)           AS highest_score,
    MIN(g.score)           AS lowest_score
FROM grade g
JOIN assignment a ON a.assignment_id = g.assignment_id
WHERE g.assignment_id = 7;


-- =============================================================
-- Task 5: List all students in a given course
-- =============================================================

-- Example: CS 101 (course_id = 1)
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    s.email
FROM student s
JOIN enrollment e ON e.student_id = s.student_id
WHERE e.course_id = 1
ORDER BY s.last_name, s.first_name;


-- =============================================================
-- Task 6: List all students in a course with all their scores
-- =============================================================

-- Example: CS 101 (course_id = 1)
SELECT
    s.first_name || ' ' || s.last_name AS student_name,
    a.assignment_name,
    g.score,
    a.max_points
FROM grade g
JOIN enrollment e  ON e.enrollment_id = g.enrollment_id
JOIN student s     ON s.student_id    = e.student_id
JOIN assignment a  ON a.assignment_id = g.assignment_id
JOIN category cat  ON cat.category_id = a.category_id
WHERE e.course_id = 1
ORDER BY s.last_name, s.first_name, cat.category_name, a.assignment_name;


-- =============================================================
-- Task 7: Add an assignment to a course
-- =============================================================

-- Add a new homework to CS 101's Homework category (category_id = 2)
INSERT INTO assignment (category_id, assignment_name, max_points)
VALUES (2, 'HW6 - OOP Basics', 100);

-- Seed a grade of 0 for every enrolled student (so no NULL gaps)
INSERT INTO grade (enrollment_id, assignment_id, score)
SELECT e.enrollment_id, (SELECT MAX(assignment_id) FROM assignment), 0
FROM enrollment e
WHERE e.course_id = 1;


-- =============================================================
-- Task 8: Change the percentages of categories for a course
-- =============================================================

-- Example: rebalance CS 101 (remove Projects category weight, shift to Tests)
-- New distribution: 10% participation, 20% homework, 70% tests, 0% projects
-- Note: always ensure weights still sum to 100 before running.
UPDATE category SET weight_percent = 70 WHERE course_id = 1 AND category_name = 'Tests';
UPDATE category SET weight_percent = 0  WHERE course_id = 1 AND category_name = 'Projects';

-- Restore original weights for the rest of the demo:
UPDATE category SET weight_percent = 50 WHERE course_id = 1 AND category_name = 'Tests';
UPDATE category SET weight_percent = 20 WHERE course_id = 1 AND category_name = 'Projects';


-- =============================================================
-- Task 9: Add 2 points to every student's score on an assignment
-- =============================================================

-- Example: add 2 points to assignment_id = 7 (CS 101 Midterm), capped at max_points
UPDATE grade
SET score = MIN(score + 2, (SELECT max_points FROM assignment WHERE assignment_id = 7))
WHERE assignment_id = 7;


-- =============================================================
-- Task 10: Add 2 points only to students whose last name contains 'Q'
-- =============================================================

-- Targets: Carol Quinn, David Qiu (last names contain 'Q')
UPDATE grade
SET score = MIN(score + 2, (SELECT max_points FROM assignment a WHERE a.assignment_id = grade.assignment_id))
WHERE assignment_id = 7
  AND enrollment_id IN (
      SELECT e.enrollment_id
      FROM enrollment e
      JOIN student s ON s.student_id = e.student_id
      WHERE s.last_name LIKE '%Q%'
        AND e.course_id = 1
  );


-- =============================================================
-- Task 11: Compute the overall grade for a student in a course
-- =============================================================

-- Grade formula:
--   For each category:
--       category_contribution = (AVG score in category / max_points) * weight_percent
--   Final grade = SUM(category_contributions)
--
-- Example: Alice (student_id=1) in CS 101 (course_id=1)

SELECT
    s.first_name || ' ' || s.last_name AS student_name,
    co.course_name,
    ROUND(SUM(cat_avg * weight_percent / 100.0), 2) AS final_grade_percent
FROM (
    -- Sub-query: average percentage per category per student-course
    SELECT
        e.enrollment_id,
        e.student_id,
        e.course_id,
        cat.category_id,
        cat.weight_percent,
        AVG(g.score / a.max_points * 100.0) AS cat_avg
    FROM grade g
    JOIN enrollment e  ON e.enrollment_id = g.enrollment_id
    JOIN assignment a  ON a.assignment_id  = g.assignment_id
    JOIN category cat  ON cat.category_id  = a.category_id
    WHERE e.student_id = 1
      AND e.course_id  = 1
    GROUP BY cat.category_id
) t
JOIN student s ON s.student_id = t.student_id
JOIN course co ON co.course_id = t.course_id;


-- =============================================================
-- Task 12: Compute the grade with the lowest score dropped
--          in each category
-- =============================================================

-- Same formula as Task 11 but excludes the single lowest-scoring
-- assignment per category before averaging.
--
-- Example: Alice (student_id=1) in CS 101 (course_id=1)

SELECT
    s.first_name || ' ' || s.last_name AS student_name,
    co.course_name,
    ROUND(SUM(cat_avg_dropped * weight_percent / 100.0), 2) AS final_grade_drop_lowest
FROM (
    SELECT
        e.student_id,
        e.course_id,
        cat.category_id,
        cat.weight_percent,
        CASE
            WHEN COUNT(*) = 1 THEN AVG(g.score / a.max_points * 100.0)
            ELSE
                (SUM(g.score / a.max_points * 100.0) - MIN(g.score / a.max_points * 100.0))
                  / (COUNT(*) - 1)
        END AS cat_avg_dropped
    FROM grade g
    JOIN enrollment e  ON e.enrollment_id = g.enrollment_id
    JOIN assignment a  ON a.assignment_id  = g.assignment_id
    JOIN category cat  ON cat.category_id  = a.category_id
    WHERE e.student_id = 1
      AND e.course_id  = 1
    GROUP BY cat.category_id
) t
JOIN student s ON s.student_id = t.student_id
JOIN course co ON co.course_id = t.course_id;
