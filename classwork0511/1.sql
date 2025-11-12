CREATE TABLE employees  (
    emp_id INT PRIMARY KEY,
    emp_name TEXT,
    dept_id INT,
    salary NUMERIC (10, 2)
);

CREATE TABLE departments(
    dept_id INT PRIMARY KEY,
    dept_name TEXT,
    location TEXT
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name TEXT,
    dept_id      INT,
    budget       NUMERIC(12,2)
);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101,'IT','Bld A'),

INSERT INTO employees () VALUES

INSERT INTO projects (project_id,) VALUES

(
    SELECT
        'Unassigned Employee' AS type,
        e.emp_name AS name,
        FORMAT ('Salary: %s', e.salary::TEXT) AS details
    FROM employees e
    WHERE e.dept_id IS NULL
)
UNION ALL
(
    SELECT
        'Unassigned Project' AS type,
        p.project_name AS name,
        FORMAT('Budget: %s', p.budget::TEXT) AS details
    FROM projects p
    WHERE p.dept_id IS NULL
)
ORDER BY type, name;

WITH emp AS (
    SELECT d.dept_id, d.dept_name, COUNT(e.emp_id)::INT AS employee_count
    FROM departments d
    LEFT JOIN employees e ON e.dept_id = d.dept_id
    GROUP BY d.dept_id, d.dept_name
),
proj AS(
    SELECT d.dept_id, COUNT(p.project_id)::INT AS project_count
    FROM departments d
    LEFT JOIN projects p ON p.project_name = d.dept_id
    GROUP BY d.dept_id
)
SELECT
    e.dept_name
    e.employe_count
    e.project_count
CASE
WHEN p.project