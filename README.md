# Abdul Nafay Saleem, Ahmed Mohammed, Rodak Tehwodoros Beckure
# Gradebook — README

## Overview

A relational grade-book system implemented in **SQLite** with a **Python** runner.
The professor can track multiple courses, categories (participation, homework,
tests, projects), assignments, and student grades. All 12 required tasks are
implemented.

---

## Design Decisions

**ENROLLMENT** is a separate bridge table rather than a direct link between STUDENT and COURSE. This cleanly models the many-to-many relationship and lets the GRADE table reference a single `enrollment_id` instead of repeating both `student_id` and `course_id` everywhere.

**CATEGORY** is its own table rather than a column on COURSE. This allows each course to define any number of grading categories with arbitrary weights, so the distribution (e.g. 10% participation, 50% tests) can vary per course and change at any time without altering the schema.

**GRADE** links ENROLLMENT and ASSIGNMENT rather than STUDENT and ASSIGNMENT. This enforces that only students who are actually enrolled in a course can receive grades for that course's assignments — an unenrolled student cannot have a grade row inserted without a valid enrollment.

---

## File manifest

| File | Purpose |
|------|---------|
| `gradebook.sql` | DDL (CREATE TABLE) + DML (INSERT) + all task queries |
| `gradebook.py`  | Python runner — executes every task and prints results |
| `test_results.txt` | Full output captured from running `gradebook.py` |
| `ER_Diagram.png` | Entity-relationship diagram |
| `README.md`     | This file |

---

## Requirements

| Tool | Version |
|------|---------|
| Python | 3.10 or later |
| SQLite | bundled with Python (`sqlite3` stdlib) |

No third-party packages are required.

---

## How to compile / run

```bash
# From the directory containing both files:
python gradebook.py
```

The script:
1. Opens an in-memory SQLite database.
2. Executes `gradebook.sql` to create tables and load sample data.
3. Runs every task (3–12) and prints results to stdout.

To save output to a file:

```bash
python gradebook.py > test_results.txt
```

---

## Database schema (summary)

```
COURSE        -> has many CATEGORY
CATEGORY      -> has many ASSIGNMENT
STUDENT       -> enrolled in COURSE via ENROLLMENT
ENROLLMENT    -> has many GRADE
ASSIGNMENT    -> has many GRADE
```

Grade formula:

```
final_grade = Σ [ (avg_score_in_category / max_points × 100) × (weight_percent / 100) ]
```

Because `weight_percent` values for a course sum to 100, this correctly weights
each category. Within a category every assignment is worth an equal share of the
category weight (e.g., 5 homeworks worth 20% → each HW = 4%).

---

## Sample data included

| Entity | Count |
|--------|-------|
| Courses | 3 (CS 101, Calculus II, Database Systems) |
| Students | 7 (two have last names containing 'Q') |
| Categories | 11 across the three courses |
| Assignments | 23 total (before Task 7) |
| Grade records | 110 total |

---

## Task reference

| # | Description |
|---|-------------|
| 2 | `CREATE TABLE` statements for all six tables |
| 3 | `INSERT` statements; `show_tables()` prints every table |
| 4 | `AVG / MAX / MIN` score for any assignment |
| 5 | List all students enrolled in a course |
| 6 | List all students with every score in a course |
| 7 | `INSERT` a new assignment + seed 0-score grades |
| 8 | `UPDATE` category weights for a course |
| 9 | `UPDATE grade SET score = MIN(score+2, max_points)` for all students |
| 10 | Same as 9 but filtered to students whose last name `LIKE '%Q%'` |
| 11 | Weighted average final grade per student |
| 12 | Same as 11 but drops the lowest score in each category |

---

## Test Cases

The following tests use the seeded data in `gradebook.sql` and the default
parameters in `gradebook.py`:

- `course_id = 1` for CS 101 — Intro to Programming
- `student_id = 1` for Alice Anderson
- `assignment_id = 7` for the CS 101 Midterm Exam

---

### Functional Tests

#### Task 3
Verify that all six tables display inserted records.

**Expected result:**

- `course` contains 3 rows
- `student` contains 7 rows
- `enrollment` contains 14 rows
- `category` contains 11 rows
- `assignment` contains 23 rows before Task 7
- `grade` contains 110 rows

---

#### Task 4
Compute average, highest, and lowest score for assignment 7 (CS 101 Midterm Exam).

**Scores going in:** Alice = 84, Bob = 68, Carol = 94, David = 72, Eve = 100

**Expected result:**

- average is 83.6
- highest is 100
- lowest is 68

---

#### Task 5
List all students in course 1.

**Expected result:**

- 5 students are returned
- names include Alice Anderson, Bob Brown, Carol Quinn, David Qiu, and Eve Evans

---

#### Task 6
List all students in course 1 and all of their scores on every assignment.

**Expected result:**

- before Task 7, course 1 has 10 assignments
- result set contains 5 × 10 = 50 rows
- each student appears once per assignment in that course

---

#### Task 7
Add `HW6 - Recursion` to course 1 under the Homework category (category\_id = 2).

**Expected result:**

- one row is inserted into `assignment` with name `HW6 - Recursion`
- course 1 then has 11 assignments
- 5 enrolled students each receive a seeded grade of 0 for the new assignment
- the new `assignment_id` is confirmed in the printed output

---

#### Task 8
Change category weights for course 1.

**Expected result (first update):**

- Participation = 10
- Homework = 20
- Tests = 55
- Projects = 15
- total weight is 100.0 — validation succeeds

**Expected result (restored weights):**

- Tests = 50, Projects = 20
- total weight is still 100.0

---

#### Task 9
Add 2 points to all scores on assignment 7 (Midterm Exam), capped at `max_points`.

**Expected result:**

| Student | Before | After |
|---------|--------|-------|
| Alice Anderson | 84 | 86 |
| Bob Brown | 68 | 70 |
| Carol Quinn | 94 | 96 |
| David Qiu | 72 | 74 |
| Eve Evans | 100 | 100 |

Eve was already at max (100) and does not exceed it.

---

#### Task 10
Add 2 points only to students on assignment 7 whose last name contains `Q`,
capped at `max_points`.

**Q students in course 1:** Carol Quinn, David Qiu

**Expected result:**

| Student | Last Name | After Task 9 | After Task 10 |
|---------|-----------|-------------|---------------|
| Alice Anderson | Anderson | 86 | 86 (unchanged) |
| Bob Brown | Brown | 70 | 70 (unchanged) |
| Carol Quinn | Quinn | 96 | 98 |
| David Qiu | Qiu | 74 | 76 |
| Eve Evans | Evans | 100 | 100 (unchanged) |

---

#### Task 11
Compute the final grade for Alice Anderson in course 1 after Tasks 7 through 10.

**Category averages (Alice's scores after all mutations):**

- Participation: 90 / 1 assignment = **90.00**
- Homework: (88 + 95 + 100 + 92 + 87 + 0) / 6 = **77.00**
  *(HW6 - Recursion was seeded at 0 in Task 7)*
- Tests: (86 + 91) / 2 = **88.50**
  *(Midterm increased by 2 in Task 9; Alice's last name has no Q so Task 10 did not apply)*
- Projects: (95 + 88) / 2 = **91.50**

**Final weighted grade (weights restored to original in Task 8):**

```
(90.00 × 0.10) + (77.00 × 0.20) + (88.50 × 0.50) + (91.50 × 0.20)
= 9.00 + 15.40 + 44.25 + 18.30
= 86.95
```

---

#### Task 12
Compute the final grade for Alice Anderson in course 1 with the lowest score in
each category dropped.

**Category averages after dropping the lowest:**

- Participation: only 1 assignment — kept as-is: **90.00**
- Homework: drop 0 (HW6) → (88 + 95 + 100 + 92 + 87) / 5 = **92.40**
- Tests: drop 86 (Midterm) → keep 91 = **91.00**
- Projects: drop 88 (Project 2) → keep 95 = **95.00**

**Final weighted grade:**

```
(90.00 × 0.10) + (92.40 × 0.20) + (91.00 × 0.50) + (95.00 × 0.20)
= 9.00 + 18.48 + 45.50 + 19.00
= 91.98
```

---

### Integrity Tests

These tests address constraint enforcement at the database and application level.

---

#### Duplicate grades are rejected
The `grade` table enforces `UNIQUE (enrollment_id, assignment_id)`.

**Test query:**
```sql
INSERT INTO grade (enrollment_id, assignment_id, score)
VALUES (1, 7, 90);
```

**Expected result:**

The insert is rejected with a `UNIQUE constraint failed` error because
enrollment 1 already has a grade for assignment 7.

---

#### Grades require a valid enrollment
The `grade` table has a foreign key on `enrollment_id` referencing `enrollment`.
With `PRAGMA foreign_keys = ON` the database rejects orphan grade rows.

**Test query:**
```sql
INSERT INTO grade (enrollment_id, assignment_id, score)
VALUES (999, 7, 90);
```

**Expected result:**

The insert is rejected with a `FOREIGN KEY constraint failed` error because
enrollment\_id 999 does not exist.

---

#### Score updates are capped at the assignment maximum
Task 9 and Task 10 both use `MIN(score + 2, max_points)` to prevent scores from
exceeding the assignment ceiling.

**Test query (mirrors Task 9):**
```sql
UPDATE grade
SET score = MIN(score + 2,
                (SELECT max_points FROM assignment a
                 WHERE a.assignment_id = grade.assignment_id))
WHERE assignment_id = 7;
```

**Expected result:**

- No score becomes greater than 100 (the `max_points` for assignment 7)
- Eve Evans, who was already at 100, stays at 100 — not 102

---

#### Category weight changes are validated at the application level
The database does not enforce that category weights sum to 100 via a trigger;
this is validated in `task8_change_weights` by reading `SUM(weight_percent)`
after the update and printing the total.

**Test (in `gradebook.py`):**
```python
task8_change_weights(conn, course_id=1, updates={"Tests": 55, "Projects": 15})
# prints: New total weight for course_id=1: 100.0%
```

**Expected result:**

The printed total is `100.0%`. If a caller supplied weights that did not sum to
100, the printed total would reveal the discrepancy. A developer should add an
assertion or exception here to harden this check.

---

#### Adding an assignment seeds zero scores for all enrolled students
When Task 7 inserts a new assignment it immediately inserts a grade row with
`score = 0` for every enrolled student, preventing NULL gaps in later grade
calculations.

**Expected result:**

After adding `HW6 - Recursion` to course 1:

- 5 new rows appear in `grade` (one per enrolled student)
- each row has `score = 0`
- Task 11's homework average reflects this: (88+95+100+92+87+**0**)/6 = 77.00
  instead of (88+95+100+92+87)/5 = 92.40
