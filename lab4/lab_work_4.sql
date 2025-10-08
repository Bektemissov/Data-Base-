-- Part 1

-- 1.1
SELECT 
  employee_id,
  (first_name || ' ' || last_name) AS full_name,
  department,
  salary
FROM employees;

-- 1.2
SELECT DISTINCT department
FROM employees;

-- 1.3
SELECT 
  project_id,
  project_name,
  budget,
  CASE 
    WHEN budget > 150000 THEN 'Large'
    WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
    ELSE 'Small'
  END AS budget_category
FROM projects;

-- 1.4
SELECT 
  (first_name || ' ' || last_name) AS full_name,
  COALESCE(email, 'No email provided') AS email_display
FROM employees;


-- Part 2

-- 2.1
SELECT *
FROM employees
WHERE hire_date > DATE '2020-01-01';

-- 2.2
SELECT *
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- 2.3
SELECT *
FROM employees
WHERE last_name ILIKE 'S%' OR last_name ILIKE 'J%';

-- 2.4
SELECT *
FROM employees
WHERE manager_id IS NOT NULL
  AND department = 'IT';


-- Part 3

-- 3.1
SELECT 
  UPPER(first_name || ' ' || last_name) AS full_name_upper,
  LENGTH(last_name) AS last_name_len,
  SUBSTRING(COALESCE(email, '---') FROM 1 FOR 3) AS email_prefix
FROM employees;

-- 3.2
SELECT 
  employee_id,
  (first_name || ' ' || last_name) AS full_name,
  salary * 1.0 * 12 AS annual_salary,
  ROUND(salary / 12.0, 2) AS monthly_salary,
  ROUND(salary * 0.10, 2) AS raise_10pct
FROM employees;

-- 3.3
SELECT 
  FORMAT('Project: %s - Budget: $%s - Status: %s', project_name, budget, status) AS project_summary
FROM projects;

-- 3.4
SELECT 
  employee_id,
  (first_name || ' ' || last_name) AS full_name,
  hire_date,
  -- Whole years using age() then extract years
  EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))::int AS years_with_company
FROM employees;


-- Part 4

-- 4.1
SELECT 
  department,
  ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY department;

-- 4.2
SELECT 
  p.project_id,
  p.project_name,
  COALESCE(SUM(a.hours_worked), 0) AS total_hours
FROM projects p
LEFT JOIN assignments a ON a.project_id = p.project_id
GROUP BY p.project_id, p.project_name
ORDER BY p.project_id;

-- 4.3
SELECT 
  department,
  COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- 4.4
SELECT 
  MAX(salary) AS max_salary,
  MIN(salary) AS min_salary,
  SUM(salary) AS total_payroll
FROM employees;


-- Part 5

-- 5.1
(
  SELECT 
    employee_id,
    (first_name || ' ' || last_name) AS full_name,
    salary
  FROM employees
  WHERE salary > 65000
)
UNION
(
  SELECT 
    employee_id,
    (first_name || ' ' || last_name) AS full_name,
    salary
  FROM employees
  WHERE hire_date > DATE '2020-01-01'
)
ORDER BY employee_id;

-- 5.2
SELECT employee_id, (first_name || ' ' || last_name) AS full_name
FROM employees
WHERE department = 'IT'
INTERSECT
SELECT employee_id, (first_name || ' ' || last_name) AS full_name
FROM employees
WHERE salary > 65000
ORDER BY employee_id;

-- 5.3
SELECT e.employee_id, (e.first_name || ' ' || e.last_name) AS full_name
FROM employees e
EXCEPT
SELECT DISTINCT e2.employee_id, (e2.first_name || ' ' || e2.last_name) AS full_name
FROM employees e2
JOIN assignments a ON a.employee_id = e2.employee_id
ORDER BY employee_id;


-- Part 6

-- 6.1
SELECT e.*
FROM employees e
WHERE EXISTS (
  SELECT 1
  FROM assignments a
  WHERE a.employee_id = e.employee_id
);

-- 6.2
SELECT DISTINCT e.employee_id, (e.first_name || ' ' || e.last_name) AS full_name
FROM employees e
WHERE e.employee_id IN (
  SELECT a.employee_id
  FROM assignments a
  JOIN projects p ON p.project_id = a.project_id
  WHERE p.status = 'Active'
)
ORDER BY e.employee_id;

-- 6.3
SELECT e.employee_id, (e.first_name || ' ' || e.last_name) AS full_name, e.salary
FROM employees e
WHERE e.salary > ANY (
  SELECT salary FROM employees WHERE department = 'Sales'
)
ORDER BY e.salary DESC;


-- Part 7

-- 7.1
WITH avg_hours AS (
  SELECT 
    employee_id, 
    AVG(hours_worked) AS avg_hours_worked
  FROM assignments
  GROUP BY employee_id
)
SELECT 
  e.employee_id,
  (e.first_name || ' ' || e.last_name) AS full_name,
  e.department,
  ROUND(COALESCE(a.avg_hours_worked, 0), 2) AS avg_hours_worked,
  RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS salary_rank_in_dept
FROM employees e
LEFT JOIN avg_hours a ON a.employee_id = e.employee_id
ORDER BY e.department, salary_rank_in_dept, full_name;

-- 7.2
SELECT 
  p.project_name,
  SUM(a.hours_worked) AS total_hours,
  COUNT(DISTINCT a.employee_id) AS employees_assigned
FROM projects p
JOIN assignments a ON a.project_id = p.project_id
GROUP BY p.project_name
HAVING SUM(a.hours_worked) > 150
ORDER BY total_hours DESC;

-- 7.3
WITH dept_stats AS (
  SELECT 
    department,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary,
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary
  FROM employees
  GROUP BY department
),
top_earners AS (
  SELECT 
    e.department,
    STRING_AGG(e.first_name || ' ' || e.last_name, ', ' ORDER BY e.last_name, e.first_name) AS highest_paid_employee
  FROM employees e
  JOIN (
    SELECT department, MAX(salary) AS max_salary
    FROM employees
    GROUP BY department
  ) m ON m.department = e.department AND m.max_salary = e.salary
  GROUP BY e.department
)
SELECT 
  d.department,
  d.total_employees,
  d.avg_salary,
  t.highest_paid_employee,
  -- Using GREATEST/LEAST as required
  GREATEST(d.max_salary, d.min_salary) AS check_greatest,
  LEAST(d.max_salary, d.min_salary) AS check_least
FROM dept_stats d
LEFT JOIN top_earners t ON t.department = d.department
ORDER BY d.department;