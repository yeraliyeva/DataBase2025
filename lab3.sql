-- Часть A: Создание базы данных и таблиц

-- Создаем базу данных 'advanced_lab'
CREATE DATABASE advanced_lab;


-- Создаем таблицу 'employees'
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,   
    first_name VARCHAR(100),     
    last_name VARCHAR(100),      
    department VARCHAR(100),     
    salary INTEGER,              
    hire_date DATE,             
    status VARCHAR(50) DEFAULT 'Active' 
);

-- Создаем таблицу 'departments'
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY, 
    dept_name VARCHAR(100),      
    budget INTEGER,              
    manager_id INTEGER           
);

-- Создаем таблицу 'projects'
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,  
    project_name VARCHAR(100),      
    dept_id INTEGER,                
    start_date DATE,                
    end_date DATE,                  
    budget INTEGER                  
);

-- Часть B: Операции INSERT

-- 2. Вставка данных с указанием только определенных столбцов
INSERT INTO employees (first_name, last_name, department)
VALUES ('John', 'Doe', 'HR');

-- 3. Вставка данных с использованием значений по умолчанию
INSERT INTO employees (salary, status)
VALUES (DEFAULT, DEFAULT);

-- 4. Вставка нескольких строк за один запрос
INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
    ('IT', 100000, 1),
    ('HR', 50000, 2),
    ('Sales', 150000, 3);

-- 5. Вставка данных с использованием выражений
INSERT INTO employees (first_name, last_name, hire_date, salary)
VALUES ('Alice', 'Smith', CURRENT_DATE, 50000 * 1.1);

-- 6. Вставка данных из SELECT
CREATE TEMPORARY TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- Часть C: Операции UPDATE

-- 7. Обновление с арифметическими выражениями
UPDATE employees
SET salary = salary * 1.1;

-- 8. Обновление с WHERE и несколькими условиями
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 9. Обновление с использованием выражения CASE
UPDATE employees
SET department = 
    CASE 
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END;

-- 10. Обновление с использованием значений по умолчанию
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. Обновление с подзапросом
UPDATE departments
SET budget = budget * 1.2
WHERE dept_id IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

-- 12. Обновление нескольких столбцов
UPDATE employees
SET salary = salary * 1.15, status = 'Promoted'
WHERE department = 'Sales';

-- Часть D: Операции DELETE

-- 13. Удаление с простым условием WHERE
DELETE FROM employees WHERE status = 'Terminated';

-- 14. Удаление с сложным условием WHERE
DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

-- 15. Удаление с подзапросом
DELETE FROM departments
WHERE dept_id NOT IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

-- 16. Удаление с использованием RETURNING
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- Часть E: Операции с NULL значениями

-- 17. Вставка с NULL значениями
INSERT INTO employees (salary, department)
VALUES (NULL, NULL);

-- 18. Обновление с обработкой NULL значений
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. Удаление с условием на NULL
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- Часть F: Операции с RETURNING

-- 20. Вставка с RETURNING
INSERT INTO employees (first_name, last_name)
VALUES ('Jane', 'Doe')
RETURNING emp_id, CONCAT(first_name, ' ', last_name);

-- 21. Обновление с RETURNING
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary AS old_salary, salary + 5000 AS new_salary;

-- 22. Удаление с RETURNING всех столбцов
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- Часть G: Сложные DML операции

-- 23. Условная вставка
INSERT INTO employees (first_name, last_name)
SELECT 'John', 'Doe'
WHERE NOT EXISTS (SELECT 1 FROM employees WHERE first_name = 'John' AND last_name = 'Doe');

-- 24. Обновление с использованием JOIN и подзапросов
UPDATE employees e
SET salary = salary * 
    (CASE 
        WHEN d.budget > 100000 THEN 1.1 
        ELSE 1.05 
    END)
FROM departments d
WHERE e.department = d.dept_name;

-- 25. Массовые операции
INSERT INTO employees (first_name, last_name, department, salary)
VALUES 
    ('Alice', 'Smith', 'IT', 60000),
    ('Bob', 'Johnson', 'HR', 55000),
    ('Charlie', 'Brown', 'Sales', 70000),
    ('David', 'Wilson', 'IT', 75000),
    ('Eve', 'Davis', 'Sales', 68000);

UPDATE employees 
SET salary = salary * 1.1 
WHERE emp_id IN (SELECT emp_id FROM employees WHERE department = 'Sales');

-- 26. Моделирование миграции данных
CREATE TABLE employee_archive AS 
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

-- 27. Сложная бизнес-логика
UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000 AND dept_id IN 
    (SELECT dept_id FROM departments WHERE dept_name IN 
    (SELECT department FROM employees GROUP BY department HAVING COUNT(*) > 3));
