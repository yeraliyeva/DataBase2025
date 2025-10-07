-- Part 1: Basic SELECT Queries

SELECT CONCAT(first_name, ' ', last_name) AS full_name, department, salary
FROM employees;

SELECT DISTINCT department FROM employees;

SELECT project_name, budget,
       CASE
           WHEN budget > 150000 THEN 'Large'
           WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
           ELSE 'Small'
       END AS budget_category
FROM projects;

SELECT CONCAT(first_name, ' ', last_name) AS full_name,
       COALESCE(email, 'No email provided') AS email
FROM employees;

-- Part 2: WHERE Clause and Comparison Operators

SELECT * FROM employees
WHERE hire_date > '2020-01-01';

SELECT * FROM employees
WHERE salary BETWEEN 60000 AND 70000;

SELECT * FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

SELECT * FROM employees
WHERE manager_id IS NOT NULL AND department = 'IT';

-- Part 3: String and Mathematical Functions

SELECT UPPER(first_name) || ' ' || UPPER(last_name) AS full_name_upper,
       LENGTH(last_name) AS last_name_length,
       SUBSTRING(email FROM 1 FOR 3) AS email_prefix
FROM employees;

SELECT first_name, last_name, salary,
       salary * 12 AS annual_salary,
       ROUND(salary / 12, 2) AS monthly_salary,
       salary * 0.1 AS raise_amount
FROM employees;

SELECT FORMAT('Project: %s - Budget: $%s - Status: %s', project_name, budget, status) AS project_info
FROM projects;

SELECT first_name, last_name, 
       EXTRACT(YEAR FROM AGE(hire_date)) AS years_with_company
FROM employees;

-- Part 4: Aggregate Functions and GROUP BY

SELECT department, AVG(salary) AS average_salary
FROM employees
GROUP BY department;

SELECT p.project_name, SUM(a.hours_worked) AS total_hours_worked
FROM assignments a
JOIN projects p ON a.project_id = p.project_id
GROUP BY p.project_name;

SELECT department, COUNT(employee_id) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(employee_id) > 1;

SELECT MAX(salary) AS max_salary, MIN(salary) AS min_salary, SUM(salary) AS total_payroll
FROM employees;

-- Part 5: Set Operations

SELECT employee_id, CONCAT(first_name, ' ', last_name) AS full_name, salary
FROM employees
WHERE salary > 65000
UNION
SELECT employee_id, CONCAT(first_name, ' ', last_name) AS full_name, salary
FROM employees
WHERE hire_date > '2020-01-01';

SELECT employee_id, CONCAT(first_name, ' ', last_name) AS full_name, salary
FROM employees
WHERE department = 'IT' AND salary > 65000
INTERSECT
SELECT employee_id, CONCAT(first_name, ' ', last_name) AS full_name, salary
FROM employees
WHERE salary > 65000;

SELECT employee_id, CONCAT(first_name, ' ', last_name) AS full_name
FROM employees
EXCEPT
SELECT DISTINCT a.employee_id, CONCAT(e.first_name, ' ', e.last_name) AS full_name
FROM employees e
JOIN assignments a ON e.employee_id = a.employee_id;

-- Part 6: Subqueries

SELECT first_name, last_name
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM assignments a
    WHERE a.employee_id = e.employee_id
);

SELECT first_name, last_name
FROM employees
WHERE employee_id IN (
    SELECT DISTINCT a.employee_id
    FROM assignments a
    JOIN projects p ON a.project_id = p.project_id
    WHERE p.status = 'Active'
);

SELECT first_name, last_name
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);

-- Part 7: Complex Queries

SELECT e.first_name, e.last_name, e.department,
       AVG(a.hours_worked) AS avg_hours_worked,
       RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS rank_by_salary
FROM employees e
JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.first_name, e.last_name, e.department;

SELECT p.project_name, SUM(a.hours_worked) AS total_hours, COUNT(DISTINCT a.employee_id) AS num_employees
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_name
HAVING SUM(a.hours_worked) > 150;

SELECT department, COUNT(employee_id) AS total_employees,
       AVG(salary) AS avg_salary,
       GREATEST(first_name || ' ' || last_name) AS highest_paid_employee
FROM employees
GROUP BY department;
