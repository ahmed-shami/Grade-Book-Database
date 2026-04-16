# Abdul Nafay Saleem, Ahmed Mohammed, Rodak Tehwodoros
# Gradebook — README

## Overview

A relational grade-book system implemented in **SQLite** with a **Python** runner.
The professor can track multiple courses, categories (participation, homework,
tests, projects), assignments, and student grades. All 12 required tasks are
implemented.

---

## File manifest

| File | Purpose |
|------|---------|
| `gradebook.sql` | DDL (CREATE TABLE) + DML (INSERT) + all task queries |
| `gradebook.py`  | Python runner — executes every task and prints results |
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

### Python runner

```bash
# From the directory containing both files:
python gradebook.py
```

The script:
1. Opens an in-memory SQLite database.
2. Executes `gradebook.sql` to create tables and load sample data.
3. Runs every task (4-12) and prints results to stdout.

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
| Categories | 10 across the three courses |
| Assignments | 23 total |
| Grade records | 115 total |

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
| 10 | Same as 9 but filtered to students whose last name LIKE '%Q%' |
| 11 | Weighted average final grade per student |
| 12 | Same as 11 but drops the lowest score in each category |

---

## Test cases

Automated run output is saved in `test_results.txt`. Quick summary:

- Task 4: Midterm Exam (`assignment_id=7`) -> avg=83.6, high=100, low=68
- Task 9/10: +2 is applied to all students on midterm, then +2 only to Quinn/Qiu
- Task 11: Alice's final grade in CS 101 -> 86.95%
- Task 12: Alice's grade with lowest-dropped -> 91.98%
