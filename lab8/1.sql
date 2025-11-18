/*
   LabWork 8 — SQL Indexes
   Student: Bektemissov Iskander | ID: 24B031706
*/

DROP VIEW IF EXISTS index_documentation CASCADE;

DROP INDEX IF EXISTS proj_name_hash_idx;
DROP INDEX IF EXISTS proj_name_btree_idx;
DROP INDEX IF EXISTS dept_name_hash_idx;
DROP INDEX IF EXISTS proj_high_budget_idx;
DROP INDEX IF EXISTS emp_salary_filter_idx;
DROP INDEX IF EXISTS employees_salary_index;
DROP INDEX IF EXISTS emp_salary_dept_idx;
DROP INDEX IF EXISTS emp_dept_salary_idx;
DROP INDEX IF EXISTS emp_name_lower_idx;
DROP INDEX IF EXISTS emp_hire_year_idx;
DROP INDEX IF EXISTS proj_budget_nulls_first_idx;
DROP INDEX IF EXISTS emp_salary_desc_idx;
DROP INDEX IF EXISTS emp_email_unique_idx;
DROP INDEX IF EXISTS emp_dept_idx;
DROP INDEX IF EXISTS emp_salary_idx;

DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;


-- Part 1: Database Setup

CREATE TABLE departments (
  dept_id   INT PRIMARY KEY,
  dept_name VARCHAR(50),
  location  VARCHAR(50)
);

CREATE TABLE employees (
  emp_id   INT PRIMARY KEY,
  emp_name VARCHAR(100),
  dept_id  INT REFERENCES departments(dept_id),
  salary   DECIMAL(10,2)
);

CREATE TABLE projects (
  proj_id   INT PRIMARY KEY,
  proj_name VARCHAR(100),
  budget    DECIMAL(12,2),
  dept_id   INT REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT',         'Building A'),
(102, 'HR',         'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith',      101, 50000),
(2, 'Jane Doe',        101, 55000),
(3, 'Mike Johnson',    102, 48000),
(4, 'Sarah Williams',  102, 52000),
(5, 'Tom Brown',       103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign',    75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade',   50000, 102);


-- Part 2: Creating Basic Indexes

-- 2.1 Simple B-tree index on salary
CREATE INDEX emp_salary_idx ON employees(salary);

-- Check indexes on employees
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

-- 2.2 Index on foreign key dept_id
CREATE INDEX emp_dept_idx ON employees(dept_id);

-- This query should use the index
SELECT * FROM employees WHERE dept_id = 101;

-- 2.3 View all indexes in public schema
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- Part 3: Multicolumn Indexes

-- 3.1 Multicolumn index (dept_id, salary)
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

-- Query that can use the multicolumn index
SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- 3.2 Multicolumn index with reversed column order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Compare queries
SELECT * FROM employees
WHERE dept_id = 102 AND salary > 50000;

SELECT * FROM employees
WHERE salary > 50000 AND dept_id = 102;


-- Part 4: Unique Indexes

-- 4.1 Unique index on email
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com'   WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'     WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'    WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Проверка уникальности (ожидается ошибка)
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- 4.2 UNIQUE constraint -> автоиндекс
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';


-- Part 5: Indexes and Sorting


-- 5.1 Index для ORDER BY salary DESC
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- 5.2 Index с NULLS FIRST по budget
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;


-- Part 6: Indexes on Expressions

-- 6.1 Function-based index для case-insensitive поиска
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

-- Этот запрос может использовать expression index
SELECT *
FROM employees
WHERE LOWER(emp_name) = 'john smith';

-- 6.2 Index на вычисляемое значение (год hire_date)
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx
ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;


-- Part 7: Managing Indexes

-- 7.1 Переименовать индекс
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname
FROM pg_indexes
WHERE tablename = 'employees';

-- 7.2 Удалить лишний индекс
DROP INDEX emp_salary_dept_idx;

-- 7.3 REINDEX
REINDEX INDEX employees_salary_index;


-- Part 8: Practical Scenarios

-- 8.1 Оптимизация частого запроса
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

-- Индекс для WHERE с частичным условием
CREATE INDEX emp_salary_filter_idx
ON employees(salary)
WHERE salary > 50000;

-- JOIN индекс уже есть: emp_dept_idx
-- ORDER BY индекс уже есть: emp_salary_desc_idx

-- 8.2 Частичный индекс на проекты с большим бюджетом
CREATE INDEX proj_high_budget_idx
ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- 8.3 Проверка использования индекса
EXPLAIN SELECT * FROM employees WHERE salary > 52000;


-- Part 9: Index Types Comparison

-- 9.1 HASH-index на dept_name
CREATE INDEX dept_name_hash_idx
ON departments USING HASH (dept_name);

SELECT * FROM departments
WHERE dept_name = 'IT';

-- 9.2 Сравнение B-tree и HASH на proj_name
CREATE INDEX proj_name_btree_idx
ON projects(proj_name);

CREATE INDEX proj_name_hash_idx
ON projects USING HASH (proj_name);

-- Equality search (оба индекса могут использоваться)
SELECT * FROM projects
WHERE proj_name = 'Website Redesign';

-- Range search (только B-tree)
SELECT * FROM projects
WHERE proj_name > 'Database';


-- Part 10: Cleanup and Best Practices

-- 10.1 Посмотреть все индексы и их размер
SELECT
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 10.2 Удалить ненужные индексы (пример)
DROP INDEX IF EXISTS proj_name_hash_idx;

-- 10.3 Документация по индексам (например, зарплатные)
DROP VIEW IF EXISTS index_documentation;

CREATE VIEW index_documentation AS
SELECT
  tablename,
  indexname,
  indexdef,
  'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;