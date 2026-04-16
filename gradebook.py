#!/usr/bin/env python3
"""
gradebook.py
Professor's Grade Book — all 12 tasks executed against an in-memory SQLite database.

Usage:
    python gradebook.py
"""

import sqlite3

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

def banner(title: str) -> None:
    width = 70
    print("\n" + "=" * width)
    print(f"  {title}")
    print("=" * width)


def print_table(cursor: sqlite3.Cursor, rows: list[tuple]) -> None:
    """Pretty-print query results using column names from the cursor description."""
    if cursor.description is None:
        print("  (no results)")
        return
    headers = [d[0] for d in cursor.description]
    if not rows:
        print("  (no rows)")
        return
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(val)))
    fmt = "  " + "  ".join(f"{{:<{w}}}" for w in col_widths)
    sep = "  " + "  ".join("-" * w for w in col_widths)
    print(fmt.format(*headers))
    print(sep)
    for row in rows:
        print(fmt.format(*[str(v) for v in row]))


# ──────────────────────────────────────────────────────────────────────────────
# Database setup
# ──────────────────────────────────────────────────────────────────────────────

def build_db(conn: sqlite3.Connection) -> None:
    """Create tables and insert sample data (Tasks 2 & 3)."""
    with open("gradebook.sql", "r", encoding="utf-8") as f:
        sql = f.read()

    # Run only schema + seed data (Tasks 2 & 3). The SQL file also includes
    # demo queries for Tasks 4-12 that should not mutate initial state here.
    setup_sql = sql.split("-- =============================================================\n-- Task 4", 1)[0]
    cur = conn.cursor()
    cur.executescript(setup_sql)
    conn.commit()


# ──────────────────────────────────────────────────────────────────────────────
# Tasks
# ──────────────────────────────────────────────────────────────────────────────

def task4_stats(conn: sqlite3.Connection, assignment_id: int) -> None:
    banner(f"Task 4 — Avg / High / Low for assignment_id={assignment_id}")
    sql = """
        SELECT
            a.assignment_name,
            ROUND(AVG(g.score), 2) AS average_score,
            MAX(g.score)           AS highest_score,
            MIN(g.score)           AS lowest_score
        FROM grade g
        JOIN assignment a ON a.assignment_id = g.assignment_id
        WHERE g.assignment_id = ?
    """
    cur = conn.execute(sql, (assignment_id,))
    rows = cur.fetchall()
    print_table(cur, rows)


def task5_list_students(conn: sqlite3.Connection, course_id: int) -> None:
    banner(f"Task 5 — Students in course_id={course_id}")
    sql = """
        SELECT s.student_id, s.first_name, s.last_name, s.email
        FROM student s
        JOIN enrollment e ON e.student_id = s.student_id
        WHERE e.course_id = ?
        ORDER BY s.last_name, s.first_name
    """
    cur = conn.execute(sql, (course_id,))
    rows = cur.fetchall()
    print_table(cur, rows)


def task6_all_scores(conn: sqlite3.Connection, course_id: int) -> None:
    banner(f"Task 6 — All students & scores in course_id={course_id}")
    sql = """
        SELECT
            s.first_name || ' ' || s.last_name AS student_name,
            cat.category_name,
            a.assignment_name,
            g.score,
            a.max_points
        FROM grade g
        JOIN enrollment e  ON e.enrollment_id = g.enrollment_id
        JOIN student s     ON s.student_id    = e.student_id
        JOIN assignment a  ON a.assignment_id = g.assignment_id
        JOIN category cat  ON cat.category_id = a.category_id
        WHERE e.course_id = ?
        ORDER BY s.last_name, cat.category_name, a.assignment_name
    """
    cur = conn.execute(sql, (course_id,))
    rows = cur.fetchall()
    print_table(cur, rows)


def task7_add_assignment(conn: sqlite3.Connection, category_id: int,
                         name: str, max_pts: float, course_id: int) -> None:
    banner(f"Task 7 — Add assignment '{name}' to category_id={category_id}")
    conn.execute(
        "INSERT INTO assignment (category_id, assignment_name, max_points) VALUES (?,?,?)",
        (category_id, name, max_pts)
    )
    new_id = conn.execute("SELECT MAX(assignment_id) FROM assignment").fetchone()[0]
    print(f"  Inserted assignment_id={new_id}")

    # Seed a 0-score grade for every student enrolled in the course
    conn.execute("""
        INSERT INTO grade (enrollment_id, assignment_id, score)
        SELECT e.enrollment_id, ?, 0
        FROM enrollment e
        WHERE e.course_id = ?
    """, (new_id, course_id))
    conn.commit()

    affected = conn.execute(
        "SELECT COUNT(*) FROM grade WHERE assignment_id=?", (new_id,)
    ).fetchone()[0]
    print(f"  Seeded 0-score grades for {affected} enrolled students.")

    # Confirm
    cur = conn.execute(
        "SELECT assignment_id, assignment_name, max_points FROM assignment WHERE assignment_id=?",
        (new_id,)
    )
    print_table(cur, cur.fetchall())


def task8_change_weights(conn: sqlite3.Connection, course_id: int,
                          updates: dict[str, float]) -> None:
    banner(f"Task 8 — Update category weights for course_id={course_id}")
    for cat_name, new_pct in updates.items():
        conn.execute(
            "UPDATE category SET weight_percent=? WHERE course_id=? AND category_name=?",
            (new_pct, course_id, cat_name)
        )
    conn.commit()
    total = conn.execute(
        "SELECT SUM(weight_percent) FROM category WHERE course_id=?", (course_id,)
    ).fetchone()[0]
    print(f"  Updated weights: {updates}")
    print(f"  New total weight for course_id={course_id}: {total}%")
    cur = conn.execute(
        "SELECT category_name, weight_percent FROM category WHERE course_id=? ORDER BY category_id",
        (course_id,)
    )
    print_table(cur, cur.fetchall())


def task9_add_points_all(conn: sqlite3.Connection, assignment_id: int, points: float) -> None:
    banner(f"Task 9 — Add {points} pts to every student on assignment_id={assignment_id}")
    conn.execute("""
        UPDATE grade
        SET score = MIN(score + ?,
                        (SELECT max_points FROM assignment a WHERE a.assignment_id = grade.assignment_id))
        WHERE assignment_id = ?
    """, (points, assignment_id))
    conn.commit()
    cur = conn.execute("""
        SELECT s.first_name || ' ' || s.last_name AS student_name, g.score
        FROM grade g
        JOIN enrollment e ON e.enrollment_id = g.enrollment_id
        JOIN student s    ON s.student_id    = e.student_id
        WHERE g.assignment_id = ?
        ORDER BY s.last_name
    """, (assignment_id,))
    print_table(cur, cur.fetchall())


def task10_add_points_Q(conn: sqlite3.Connection, assignment_id: int,
                         points: float, course_id: int) -> None:
    banner(f"Task 10 — Add {points} pts (last name contains 'Q') on assignment_id={assignment_id}")
    conn.execute("""
        UPDATE grade
        SET score = MIN(score + ?,
                        (SELECT max_points FROM assignment a WHERE a.assignment_id = grade.assignment_id))
        WHERE assignment_id = ?
          AND enrollment_id IN (
              SELECT e.enrollment_id
              FROM enrollment e
              JOIN student s ON s.student_id = e.student_id
              WHERE s.last_name LIKE '%Q%'
                AND e.course_id = ?
          )
    """, (points, assignment_id, course_id))
    conn.commit()
    cur = conn.execute("""
        SELECT s.first_name || ' ' || s.last_name AS student_name,
               s.last_name, g.score
        FROM grade g
        JOIN enrollment e ON e.enrollment_id = g.enrollment_id
        JOIN student s    ON s.student_id    = e.student_id
        WHERE g.assignment_id = ?
        ORDER BY s.last_name
    """, (assignment_id,))
    print_table(cur, cur.fetchall())


def task11_student_grade(conn: sqlite3.Connection, student_id: int, course_id: int) -> None:
    banner(f"Task 11 — Final grade for student_id={student_id}, course_id={course_id}")
    sql = """
        SELECT
            s.first_name || ' ' || s.last_name AS student_name,
            co.course_name,
            ROUND(SUM(cat_avg * weight_percent / 100.0), 2) AS final_grade_percent
        FROM (
            SELECT
                e.student_id, e.course_id,
                cat.category_id, cat.weight_percent,
                AVG(g.score / a.max_points * 100.0) AS cat_avg
            FROM grade g
            JOIN enrollment e  ON e.enrollment_id = g.enrollment_id
            JOIN assignment a  ON a.assignment_id  = g.assignment_id
            JOIN category cat  ON cat.category_id  = a.category_id
            WHERE e.student_id = ? AND e.course_id = ?
            GROUP BY cat.category_id
        ) t
        JOIN student s ON s.student_id = t.student_id
        JOIN course co ON co.course_id = t.course_id
    """
    cur = conn.execute(sql, (student_id, course_id))
    rows = cur.fetchall()
    print_table(cur, rows)


def task12_grade_drop_lowest(conn: sqlite3.Connection, student_id: int, course_id: int) -> None:
    banner(f"Task 12 — Grade (drop lowest/category) for student_id={student_id}, course_id={course_id}")
    sql = """
        SELECT
            s.first_name || ' ' || s.last_name AS student_name,
            co.course_name,
            ROUND(SUM(cat_avg_dropped * weight_percent / 100.0), 2) AS final_grade_drop_lowest
        FROM (
            SELECT
                e.student_id, e.course_id,
                cat.category_id, cat.weight_percent,
                CASE
                    -- If there is only one assignment in a category, keep it.
                    WHEN COUNT(*) = 1 THEN AVG(g.score / a.max_points * 100.0)
                    ELSE
                        (SUM(g.score / a.max_points * 100.0) - MIN(g.score / a.max_points * 100.0))
                        / (COUNT(*) - 1)
                END AS cat_avg_dropped
            FROM grade g
            JOIN enrollment e  ON e.enrollment_id = g.enrollment_id
            JOIN assignment a  ON a.assignment_id  = g.assignment_id
            JOIN category cat  ON cat.category_id  = a.category_id
            WHERE e.student_id = ? AND e.course_id = ?
            GROUP BY cat.category_id
        ) t
        JOIN student s ON s.student_id = t.student_id
        JOIN course co ON co.course_id = t.course_id
    """
    cur = conn.execute(sql, (student_id, course_id))
    rows = cur.fetchall()
    print_table(cur, rows)


# ──────────────────────────────────────────────────────────────────────────────
# Show tables (Task 3)
# ──────────────────────────────────────────────────────────────────────────────

def show_tables(conn: sqlite3.Connection) -> None:
    tables = ["course", "student", "enrollment", "category", "assignment", "grade"]
    for tbl in tables:
        banner(f"Task 3 — Table: {tbl}")
        cur = conn.execute(f"SELECT * FROM {tbl}")
        print_table(cur, cur.fetchall())


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

def main() -> None:
    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys = ON")

    print("Building database from gradebook.sql …")
    build_db(conn)

    # Task 3 — show every table
    show_tables(conn)

    # Task 4 — stats for CS 101 Midterm (assignment_id=7)
    task4_stats(conn, assignment_id=7)

    # Task 5 — students in CS 101 (course_id=1)
    task5_list_students(conn, course_id=1)

    # Task 6 — all students + scores in CS 101 (course_id=1)
    task6_all_scores(conn, course_id=1)

    # Task 7 — add HW6 to CS 101 Homework (category_id=2, course_id=1)
    task7_add_assignment(conn, category_id=2, name="HW6 - Recursion",
                         max_pts=100, course_id=1)

    # Task 8 — rebalance CS 101 weights (tests up, participation steady)
    task8_change_weights(conn, course_id=1, updates={
        "Tests": 55,
        "Projects": 15,
    })
    # restore for remaining tasks
    task8_change_weights(conn, course_id=1, updates={
        "Tests": 50,
        "Projects": 20,
    })

    # Task 9 — add 2 pts to CS 101 Midterm (assignment_id=7)
    task9_add_points_all(conn, assignment_id=7, points=2)

    # Task 10 — add 2 pts to Quinn/Qiu on CS 101 Midterm
    task10_add_points_Q(conn, assignment_id=7, points=2, course_id=1)

    # Task 11 — Alice's final grade in CS 101
    task11_student_grade(conn, student_id=1, course_id=1)

    # Task 12 — Alice's final grade with lowest dropped
    task12_grade_drop_lowest(conn, student_id=1, course_id=1)

    conn.close()
    print("\n\nDone. All 12 tasks completed successfully.\n")


if __name__ == "__main__":
    main()
