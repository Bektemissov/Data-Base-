/*
   LabWork 7 — SQL Views and Roles
   Student: Bektemissov Iskander | ID: 24B031706
 */

DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv CASCADE;
DROP MATERIALIZED VIEW IF EXISTS project_stats_mv CASCADE;
DROP VIEW IF EXISTS dept_dashboard CASCADE;
DROP VIEW IF EXISTS high_budget_projects CASCADE;
DROP VIEW IF EXISTS audit_high_projects CASCADE;
DROP VIEW IF EXISTS it_employees CASCADE;
DROP VIEW IF EXISTS employee_salaries CASCADE;
DROP VIEW IF EXISTS top_performers CASCADE;
DROP VIEW IF EXISTS employee_details CASCADE;
DROP VIEW IF EXISTS dept_statistics CASCADE;
DROP VIEW IF EXISTS project_overview CASCADE;
DROP VIEW IF EXISTS high_earners CASCADE;

DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
  dept_id   INT PRIMARY KEY,
  dept_name TEXT,
  location  TEXT
);

CREATE TABLE employees (
  emp_id   INT PRIMARY KEY,
  emp_name TEXT,
  dept_id  INT REFERENCES departments(dept_id),
  salary   NUMERIC(12,2)
);

CREATE TABLE projects (
  project_id   INT PRIMARY KEY,
  project_name TEXT,
  dept_id      INT REFERENCES departments(dept_id),
  budget       NUMERIC(12,2)
);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101,'IT','Building A'),
(102,'HR','Building B'),
(103,'Finance','Building C'),
(104,'Marketing','Building D');

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1,'John Smith',   101, 50000),
(2,'Jane Doe',     102, 60000),
(3,'Mike Johnson', 101, 55000),
(4,'Sarah Williams',103,65000),
(5,'Tom Brown',    NULL,45000);  -- no dept (orphan)

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1,'Website Redesign', 101, 100000),
(2,'CRM Implementation',102,200000),
(3,'Marketing Campaign',104, 80000),
(4,'Cloud Migration',  101, 150000),
(5,'AI Research',      NULL,200000); -- no dept (orphan)


/* Part 2: Basic Views */

/* 2.1 Simple view: employee_details (only employees assigned to a department) */
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Test:
-- SELECT * FROM employee_details;
-- Q: сколько строк? Tom Brown не появится, потому что у него NULL dept_id (JOIN исключает)


/* 2.2 Aggregation view: dept_statistics (include depts with zero employees) */
CREATE OR REPLACE VIEW dept_statistics AS
SELECT
  d.dept_id,
  d.dept_name,
  COALESCE(COUNT(e.emp_id),0) AS employee_count,
  ROUND(COALESCE(AVG(e.salary),0)::NUMERIC,2) AS avg_salary,
  COALESCE(MAX(e.salary),0) AS max_salary,
  COALESCE(MIN(e.salary),0) AS min_salary
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Test:
-- SELECT * FROM dept_statistics ORDER BY employee_count DESC;


/* 2.3 Multiple joins: project_overview */
CREATE OR REPLACE VIEW project_overview AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  d.dept_name,
  d.location,
  COALESCE(t.team_size,0) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(emp_id) AS team_size
  FROM employees GROUP BY dept_id
) t ON t.dept_id = d.dept_id;

-- Test:
-- SELECT * FROM project_overview;


/* 2.4 Filtering view: high_earners (salary > 55000) */
CREATE OR REPLACE VIEW high_earners AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

-- Test:
-- SELECT * FROM high_earners;
-- Q: увидите ли всех высокооплачиваемых сотрудников? Да — view отражает данные на момент запроса,
-- но если позже добавите сотрудника с salary>55000, он появится в view (это виртуальный view).


/* Part 3: Modifying / Managing Views */

/* 3.1 Replace employee_details: add salary_grade */
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id, e.emp_name, e.salary,
       CASE
         WHEN e.salary > 60000 THEN 'High'
         WHEN e.salary > 50000 THEN 'Medium'
         ELSE 'Standard'
       END AS salary_grade,
       d.dept_name, d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Test:
-- SELECT * FROM employee_details;

/* 3.2 Rename view high_earners -> top_performers */
DROP VIEW IF EXISTS top_performers;
ALTER VIEW high_earners RENAME TO top_performers;

-- Test:
-- SELECT * FROM top_performers;

/* 3.3 Create and drop a temporary view */
CREATE TEMP VIEW temp_view AS
SELECT emp_id, emp_name, salary FROM employees WHERE salary < 50000;
-- Test:
-- SELECT * FROM temp_view;
DROP VIEW IF EXISTS temp_view;


/* Part 4: Updatable Views */

/* 4.1 Updatable view: employee_salaries */
CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- View is simple SELECT from single base table => updatable in PG by default (for these cols).

/* 4.2 Update through view: change John Smith salary to 52000 */
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

-- Verify underlying table:
-- SELECT * FROM employees WHERE emp_name='John Smith';
-- Q: да — обновится, потому что view напрямую мапится на таблицу employees

/* 4.3 Insert through view: add Alice Johnson (emp_id:6) */
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6,'Alice Johnson',102,58000);

-- Verify:
-- SELECT * FROM employees WHERE emp_name='Alice Johnson';
-- Q: INSERT успешен — добавлена строка в базовую таблицу employees

/* 4.4 View with CHECK OPTION: it_employees (dept_id = 101) */
CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- Try to insert employee from other dept (should fail)
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary) VALUES (7,'Bob Wilson',103,60000);
-- Expected error: нарушает CHECK OPTION — вставка не разрешена, потому что строка не удовлетворяет условию представления.


/* Part 5: Materialized Views */

/* 5.1 dept_summary_mv WITH DATA */
CREATE MATERIALIZED VIEW IF NOT EXISTS dept_summary_mv AS
SELECT
  d.dept_id,
  d.dept_name,
  COUNT(e.emp_id) AS total_employees,
  COALESCE(SUM(e.salary),0)::NUMERIC(14,2) AS total_salaries,
  COUNT(p.project_id) AS total_projects,
  COALESCE(SUM(p.budget),0)::NUMERIC(14,2) AS total_project_budget
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
LEFT JOIN projects p ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;

-- Test:
-- SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

/* 5.2 Refresh materialized view after inserting new employee */
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES (8,'Charlie Brown',101,54000);
-- Query before refresh:
-- SELECT * FROM dept_summary_mv WHERE dept_id=101;
-- REFRESH:
REFRESH MATERIALIZED VIEW dept_summary_mv;
-- Query after:
-- SELECT * FROM dept_summary_mv WHERE dept_id=101;
-- Q: до REFRESH mv не содержит Charlie; после REFRESH — содержит (материализованное кеширование)

/* 5.3 Concurrent refresh: requires unique index on matview and cannot run inside transaction */
-- Create unique index on dept_id (if not exists)
CREATE UNIQUE INDEX IF NOT EXISTS dept_summary_mv_dept_id_idx ON dept_summary_mv (dept_id);

-- To refresh concurrently (must be run outside transaction block):
-- REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
-- Note: CONCURRENTLY allows reads during refresh (no exclusive lock), but requires unique index (and PostgreSQL >= 9.4).

/* 5.4 Materialized view WITH NO DATA */
CREATE MATERIALIZED VIEW IF NOT EXISTS project_stats_mv
AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  d.dept_name,
  COALESCE(e_count.cnt,0) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(emp_id) AS cnt FROM employees GROUP BY dept_id
) e_count ON e_count.dept_id = d.dept_id
WITH NO DATA;

-- Try to query:
-- SELECT * FROM project_stats_mv; -- returns rows after REFRESH MATERIALIZED VIEW project_stats_mv;

-- To populate:
-- REFRESH MATERIALIZED VIEW project_stats_mv;
-- Then:
-- SELECT * FROM project_stats_mv;


/* Part 6: Database Roles (needs superuser to create roles) */

/* 6.1 Create basic roles */
-- analyst (no login)
DO $$ BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='analyst') THEN
     CREATE ROLE analyst;
   END IF;
END$$;

DO $$ BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='data_viewer') THEN
     CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
   END IF;
END$$;

DO $$ BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='report_user') THEN
     CREATE ROLE report_user LOGIN PASSWORD 'report456';
   END IF;
END$$;

-- 6.2 Roles with attributes (db_creator, user_manager, admin_user)
DO $$ BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='db_creator') THEN
     CREATE ROLE db_creator CREATEDB LOGIN PASSWORD 'creator789';
   END IF;
END$$;

DO $$ BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='user_manager') THEN
     CREATE ROLE user_manager CREATEROLE LOGIN PASSWORD 'manager101';
   END IF;
END$$;

-- Warning: creating a superuser should be done very carefully
-- DO $$ BEGIN
--    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='admin_user') THEN
--      CREATE ROLE admin_user SUPERUSER LOGIN PASSWORD 'admin999';
--    END IF;
-- END$$;

/* 6.3 Grant privileges */
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

/* 6.4 Group roles & users */
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='hr_team') THEN
    CREATE ROLE hr_team;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='finance_team') THEN
    CREATE ROLE finance_team;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='it_team') THEN
    CREATE ROLE it_team;
  END IF;
END$$;

-- Create user accounts
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='hr_user1') THEN
    CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='hr_user2') THEN
    CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='finance_user1') THEN
    CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';
  END IF;
END$$;

-- Assign users to groups
GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

-- Grant privileges to groups
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

/* 6.5 Revoke examples (apply as needed) */
-- REVOKE UPDATE ON employees FROM hr_team;
-- REVOKE hr_team FROM hr_user2;
-- REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

/* 6.6 Modify role attributes examples */
-- Add LOGIN to existing analyst and set password
-- ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
-- Make user_manager a superuser (CAUTION)
-- ALTER ROLE user_manager WITH SUPERUSER;
-- Remove password from analyst:
-- ALTER ROLE analyst WITH PASSWORD NULL;
-- Set connection limit for data_viewer:
-- ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;


/* Part 7: Advanced Role Management */

/* 7.1 Role hierarchies */
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='read_only') THEN
    CREATE ROLE read_only;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='junior_analyst') THEN
    CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='senior_analyst') THEN
    CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';
  END IF;
END$$;

-- Grant read_only membership to both
GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

-- Grant SELECT to read_only on all public tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

-- Additional privilege to senior_analyst
GRANT INSERT, UPDATE ON employees TO senior_analyst;

/* 7.2 Object ownership transfer (example) */
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='project_manager') THEN
    CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
  END IF;
END$$;

-- Transfer ownership of view and table (must be owner or superuser)
-- ALTER VIEW dept_statistics OWNER TO project_manager;
-- ALTER TABLE projects OWNER TO project_manager;

-- Check ownership:
-- SELECT tablename, tableowner FROM pg_tables WHERE schemaname='public';

/* 7.3 Reassign and drop roles (example) */
-- DO $$ BEGIN
--   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='temp_owner') THEN
--     CREATE ROLE temp_owner LOGIN;
--   END IF;
-- END$$;
-- CREATE TABLE temp_table (id INT);
-- ALTER TABLE temp_table OWNER TO temp_owner;
-- -- Reassign objects and drop role (run as superuser):
-- REASSIGN OWNED BY temp_owner TO postgres;
-- DROP OWNED BY temp_owner;
-- DROP ROLE IF EXISTS temp_owner;

/* 7.4 Row-level security with views (role-specific views) */
CREATE OR REPLACE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON hr_employee_view TO hr_team;
GRANT SELECT ON finance_employee_view TO finance_team;


/* Part 8: Practical Scenarios */

/* 8.1 Department dashboard view: dept_dashboard */
CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
  d.dept_id,
  d.dept_name,
  d.location,
  COALESCE(COUNT(e.emp_id),0) AS employee_count,
  ROUND(COALESCE(AVG(e.salary),0)::NUMERIC,2) AS avg_salary,
  COALESCE(COUNT(p.project_id),0) AS active_projects,
  COALESCE(SUM(p.budget),0)::NUMERIC(14,2) AS total_project_budget,
  CASE
    WHEN COUNT(e.emp_id) = 0 THEN 0
    ELSE ROUND(COALESCE(SUM(p.budget),0) / NULLIF(COUNT(e.emp_id),0)::NUMERIC,2)
  END AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
LEFT JOIN projects p ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;

-- Test:
-- SELECT * FROM dept_dashboard ORDER BY employee_count DESC;

/* 8.2 Audit view: high_budget_projects */
ALTER TABLE projects ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  d.dept_name,
  p.created_date,
  CASE
    WHEN p.budget > 150000 THEN 'Critical Review Required'
    WHEN p.budget > 100000 THEN 'Management Approval Needed'
    ELSE 'Standard Process'
  END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

-- Test:
-- SELECT * FROM high_budget_projects;

/* 8.3 Access control system: multi-level roles & users */
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='viewer_role') THEN
    CREATE ROLE viewer_role;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='entry_role') THEN
    CREATE ROLE entry_role;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='analyst_role') THEN
    CREATE ROLE analyst_role;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='manager_role') THEN
    CREATE ROLE manager_role;
  END IF;
END$$;

-- Create users alice, bob, charlie
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='alice') THEN
    CREATE ROLE alice LOGIN PASSWORD 'alice123';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='bob') THEN
    CREATE ROLE bob LOGIN PASSWORD 'bob123';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='charlie') THEN
    CREATE ROLE charlie LOGIN PASSWORD 'charlie123';
  END IF;
END$$;

-- Role hierarchy and privileges
GRANT viewer_role TO entry_role;   -- entry_role inherits viewer_role
GRANT entry_role TO analyst_role;
GRANT analyst_role TO manager_role;

-- Grant SELECT on all tables/views to viewer_role
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO viewer_role;

-- Entry role: INSERT on employees, projects
GRANT INSERT ON employees, projects TO entry_role;

-- Analyst: UPDATE on employees, projects
GRANT UPDATE ON employees, projects TO analyst_role;

-- Manager: DELETE on employees, projects
GRANT DELETE ON employees, projects TO manager_role;

-- Assign users:
GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
