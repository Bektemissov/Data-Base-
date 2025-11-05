/* ===========================================================
   Lab 6 — SQL JOINs (PostgreSQL / DataGrip)
   Student: Bektemissov Iskander | ID: 24B031706
   =========================================================== */

DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

/* Part 1. Database Setup */
CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id  INT,
    salary   DECIMAL(10,2)
);

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id      INT,
    budget       DECIMAL(10,2)
);

/*  данные */
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith',     101, 50000),
(2, 'Jane Doe',       102, 60000),
(3, 'Mike Johnson',   101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown',     NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT',       'Building A'),
(102, 'HR',       'Building B'),
(103, 'Finance',  'Building C'),
(104, 'Marketing','Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training',102,  50000),
(3, 'Budget Analysis',  103,  75000),
(4, 'Cloud Migration',  101, 150000),
(5, 'AI Research',     NULL, 200000);

/* Part 2. CROSS JOIN  */

-- Ex 2.1: базовый CROSS JOIN
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- Для контроля количества строк (N×M):
SELECT (SELECT COUNT(*) FROM employees) * (SELECT COUNT(*) FROM departments) AS theoretical_count;

-- Ex 2.2: альтернативные синтаксисы CROSS JOIN
-- (a) запятая в FROM
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- (b) INNER JOIN ... ON TRUE
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- Ex 2.3: практический CROSS — матрица доступности «сотрудник × проект»
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;

/* Part 3. INNER JOIN */

-- Ex 3.1: сотрудники с названиями департаментов (только у кого есть департамент)
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Ex 3.2: то же, но USING
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

-- Ex 3.3: NATURAL INNER JOIN (соединит по одинаковым именам столбцов — здесь это dept_id)
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- Ex 3.4: мульти-JOIN: сотрудник + департамент + проект
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees   e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects   p ON d.dept_id = p.dept_id
ORDER BY e.emp_name, p.project_name;

/* Part 4. LEFT JOIN */

-- Ex 4.1: все сотрудники + инфо департамента (включая без департамента)
SELECT e.emp_name,
       e.dept_id AS emp_dept,
       d.dept_id AS dept_dept,
       d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- Ex 4.2: LEFT JOIN c USING
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

-- Ex 4.3: сотрудники без департамента
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- Ex 4.4: все департаменты + количество сотрудников (включая 0)
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC, d.dept_name;

/* Part 5. RIGHT JOIN */

-- Ex 5.1: все департаменты + их сотрудники (включая пустые департаменты)
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- Ex 5.2: эквивалент через LEFT JOIN (меняем порядок таблиц)
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- Ex 5.3: департаменты без сотрудников
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

/* Part 6. FULL JOIN */

-- Ex 6.1: все сотрудники и все департаменты, NULL где нет совпадений
SELECT e.emp_name,
       e.dept_id AS emp_dept,
       d.dept_id AS dept_dept,
       d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
ORDER BY COALESCE(d.dept_id, e.dept_id), e.emp_name NULLS LAST;

-- Ex 6.2: все департаменты и все проекты (в т.ч. проекты без департамента)
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name NULLS LAST, p.project_name NULLS LAST;

-- Ex 6.3: «сиротские» записи с обеих сторон (без совпадений)
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL
ORDER BY record_status, e.emp_name NULLS LAST, d.dept_name NULLS LAST;

/* Part 7. ON vs WHERE */

-- Ex 7.1: фильтр по location в ON (LEFT JOIN) — сотрудники сохраняются, матчится только Building A
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.dept_id
 AND d.location = 'Building A';

-- Ex 7.2: тот же фильтр, но в WHERE (LEFT JOIN) — превращается по сути в INNER для этих строк
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- Ex 7.3: повторить 7.1 и 7.2 c INNER JOIN — разницы в результате не будет
-- (а) фильтр в ON
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d
  ON e.dept_id = d.dept_id
 AND d.location = 'Building A';

-- (б) фильтр в WHERE
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

/* Part 8. Complex JOIN Scenarios */

-- Ex 8.1: «все департаменты» + (если есть) сотрудники + (если есть) проекты
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects  p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name, p.project_name;

-- Ex 8.2: self-join (добавим manager_id и обновим примеры)
ALTER TABLE employees ADD COLUMN IF NOT EXISTS manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id IN (1,2,4,5);
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY employee, manager NULLS LAST;

-- Ex 8.3: департаменты, где средняя зарплата > 50 000
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000
ORDER BY avg_salary DESC;



-- SELECT * FROM employees ORDER BY emp_id;
-- SELECT * FROM departments ORDER BY dept_id;
-- SELECT * FROM projects ORDER BY project_id;