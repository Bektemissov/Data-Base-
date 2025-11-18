CREATE OR REPLACE VIEW employee_directory AS SELECT
    e.emp_name,
    e.dept_name,
    d.location,
    e.salary,
    CASE
        WHEN e.salary > 55000 THEN 'High earner'
        ELSE 'Standard'
    END AS status
FROM employees e
JOIN departments d ON e.dept_id = d.dept.id
ORDER BY d.dept_name, e.emp_name;


CREATE OR REPLACE VIEW project_summary AS SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    CASE
        WHEN p.budget > 80000 THEN 'Large'
        WHEN p.budget > 50000 THEN 'Medium'
        ELSE 'Small'
    END AS project size
FROM projects p
JOIN departments d ON p.dept_id = d.dept.id;


CREATE OR REPLACE VIEW employee_directory AS SELECT
    e.emp_name,
    e.dept_name,
    d.location,
    e.salary,
    CASE
        WHEN e.salary > 55000 THEN 'High earner'
        ELSE 'Standard'
    END AS status
    CASE
        WHEN d.dept_name ILIKE '%IT%' OR d.dept_name ILIKE '%Development%' THEN 'Technical'
FROM employees e
JOIN departments d ON e.dept_id = d.dept.id
ORDER BY d.dept_name, e.emp_name;

ALTER VIEW project_summary RENAME TO project_overview;

DROP VIEW project_overview;



CREATE materialized VIEW dept_summary AS SELECT
    d.dept_name
    COUNT(e.emp_id) AS employee_count,
    COUNT(p.project_id) AS project_count,




