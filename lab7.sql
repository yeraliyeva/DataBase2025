--part2
--2.1
CREATE OR REPLACE VIEW employee_details AS
    SELECT
        e.emp_id,
        e.emp_name,
        e.salary,
        d.dept_name,
        d.location
FROM employees6 e
JOIN departments6 d ON d.dept_id=e.dept_id
WHERE e.dept_id IS NOT NULL;
SELECT * FROM employee_details;

--2.2
CREATE OR REPLACE VIEW dept_statistic AS
    SELECT
        d.dept_id,
        d.dept_name,
        COUNT(e.emp_id) AS count_of_employee,
        ROUND(AVG(e.salary)::numeric, 2)AS avarage_salary,
        MAX(e.salary) AS max_salary,
        MIN(e.salary) AS min_salary
FROM departments6 d
LEFT JOIN employees6 e ON d.dept_id=e.dept_id
GROUP BY d.dept_id, d.dept_name;
SELECT * FROM dept_statistic ORDER BY count_of_employee DESC;

--2.3
CREATE OR REPLACE VIEW project_overview AS
    SELECT
        p.project_id,
        p.project_name,
        p.budget,
        d.dept_name,
        d.location,
        COUNT(e.emp_id) AS tean_size
FROM projects6 p
JOIN departments6 d ON d.dept_id=p.dept_id
LEFT JOIN employees6 e ON e.dept_id=d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;

--2.4
CREATE OR REPLACE VIEW high_earners AS
    SELECT
        e.emp_id,
        e.emp_name,
        e.salary,
        d.dept_name
FROM employees6 e
LEFT JOIN departments6 d ON d.dept_id=e.dept_id
WHERE e.salary>55000;

--part3
--3.1
CREATE OR REPLACE VIEW employee_details AS
    SELECT
        e.emp_id,
        e.emp_name,
        e.salary,
        d.dept_name,
        d.location,
        CASE
            WHEN e.salary > 60000 THEN 'High'
            WHEN e.salary > 50000 THEN 'Medium'
            ELSE 'Standard'
        END AS salary_grade
FROM employees6 e
JOIN departments6 d ON d.dept_id=e.dept_id
WHERE e.dept_id IS NOT NULL;
--3.2
DO $$
    BEGIN
        IF EXISTS(SELECT 1 FROM pg_views WHERE viewname='high_earners') THEN
            EXECUTE 'ALTER VIEW high_earners RENAME TO top_performers';
        end if;
    end$$;
--SELECT * FROM top_performers;
--3.3
CREATE TEMP VIEW temp_view AS
    SELECT * FROM employees6 WHERE salary < 50000;
DROP VIEW IF EXISTS temp_view;

--part4
--4.1
CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees6;

--4.2
UPDATE employee_salaries
SET salary=52000
WHERE emp_name='John Smith';

SELECT * FROM employees6 WHERE emp_name = 'John Smith';

--4.3
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

--4.4
CREATE OR REPLACE VIEW it_employees AS
    SELECT emp_id, emp_name, dept_id, salary
FROM employees6 e
WHERE dept_id=101
WITH LOCAL CHECK OPTION;

INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);

--part5
--5.1
DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv CASCADE;
CREATE MATERIALIZED VIEW dept_summary_mv AS
    SELECT
        d.dept_id,
        d.dept_name,
        COALESCE(e.total_employees, 0) AS total_employee,
        COALESCE(e.total_salaries, 0) AS total_salaries,
        COALESCE(p.total_projects, 0) AS total_projects,
        COALESCE(p.total_projracts_budget, 0) AS total_budget
FROM departments6 d
LEFT JOIN (
    SELECT dept_id,
           COUNT(*) AS total_employees,
           SUM(salary) AS total_salaries
    FROM employees6
    GROUP BY dept_id
) e ON e.dept_id=d.dept_id
LEFT JOIN (
    SELECT dept_id,
           COUNT(*) AS total_projects,
           SUM(budget) AS total_projracts_budget
    FROM projects6
    GROUP BY dept_id
) p ON p.dept_id=d.dept_id
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employee DESC;
--5.2
INSERT INTO employees6 (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

REFRESH MATERIALIZED VIEW dept_summary_mv;
SELECT * FROM dept_summary_mv WHERE dept_id = 101;

--5.3
CREATE UNIQUE INDEX IF NOT EXISTS idx_dept_summary_mv_dept_id
ON dept_summary_mv(dept_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

--5.4
DROP MATERIALIZED VIEW IF EXISTS projects_stats_mv CASCADE;
CREATE MATERIALIZED VIEW projects_stats_mv AS
    SELECT
        p.project_id,
        p.project_name,
        p.budget,
        d.dept_name,
        COUNT(e.emp_id) AS employee_count
FROM projects6 p
JOIN departments6 d ON d.dept_id=p.dept_id
LEFT JOIN employees6 e ON e.dept_id=d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;
SELECT * FROM projects_stats_mv;
REFRESH MATERIALIZED VIEW projects_stats_mv;

--part6
--6.1
DO $$BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='analyst') THEN
        CREATE ROLE analyst;
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='data_viewer') THEN
        CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='report_user') THEN
        CREATE ROLE report_user WITH PASSWORD 'report456';
    end if;
end$$;
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

--6.2
DO $$BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='db_creator') THEN
        CREATE ROLE db_creator LOGIN CREATEDB PASSWORD 'creator789';
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='user_manager') THEN
        CREATE ROLE user_manager LOGIN CREATEROLE PASSWORD 'manager101';
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='admin_user') THEN
        CREATE ROLE admin_user LOGIN SUPERUSER PASSWORD 'admin999';
    end if;
end$$;

--6.3
GRANT SELECT ON TABLE employees6, departments6, projects6 TO analyst;
GRANT ALL PRIVILEGES ON TABLE employee_details TO data_viewer;
GRANT SELECT, INSERT ON TABLE employees6 TO report_user;

--6.4
DO $$BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='hr_team') THEN
        CREATE ROLE hr_team;
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='finance_team') THEN
        CREATE ROLE finance_team;
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='it_team') THEN
        CREATE ROLE it_team;
    end if;
end$$;

DO $$BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='hr_user1') THEN
        CREATE USER hr_user1 PASSWORD 'hr001';
    end if;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='hr_user2') THEN
        CREATE USER hr_user2 PASSWORD 'hr002';
    end if;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='finance_user1') THEN
        CREATE USER finance_user1 PASSWORD 'fin001';
    end if;
end$$;

GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON TABLE employees6 TO hr_team;
GRANT SELECT ON TABLE dept_statistic TO finance_team;

--6.5
REVOKE UPDATE ON TABLE employees6 FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON TABLE employee_details FROM data_viewer;

--6.6
ALTER ROLE analyst LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager SUPERUSER;
ALTER ROLE analyst PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;

--part7
--7.1
DO $$BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='read_only') THEN
        CREATE USER read_only;
    end if;
end$$;
GRANT USAGE ON SCHEMA public TO read_only;

DO $$BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='junior_analyst') THEN
        CREATE USER junior_analyst LOGIN PASSWORD 'junior123';
    end if;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='senior_analyst') THEN
        CREATE USER senior_analyst LOGIN PASSWORD 'senior123';
    end if;
end$$;

GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON TABLE employees6 TO senior_analyst;
--7.2
DO $$BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='project_manager') THEN
        CREATE USER project_manager LOGIN PASSWORD 'pm123';
    end if;
end$$;
ALTER VIEW dept_statistic OWNER TO project_manager;
ALTER TABLE projects6 OWNER TO project_manager;
 --7.3
DO $$BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='temp_owner') THEN
    CREATE ROLE temp_owner LOGIN;
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS temp_table(id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

--7.4
CREATE OR REPLACE VIEW hr_employee_view AS
    SELECT * FROM employees6 WHERE dept_id=102;
GRANT SELECT ON TABLE hr_employee_view TO hr_team;

CREATE OR REPLACE VIEW finance_employee_view AS
    SELECT emp_id, emp_name, salary FROM employees6;
GRANT SELECT ON TABLE finance_employee_view TO finance_team;

--part8
--8.1
CREATE OR REPLACE VIEW dept_dashboard AS
    SELECT
        d.dept_name,
        d.location,
        COALESCE(e.total_employees, 0) AS employee_count,
        ROUND(COALESCE(e.avg_salary, 0)::numeric, 2) AS average_salary,
        COALESCE(p.total_projects, 0) AS active_projects,
        COALESCE(p.total_budget, 0) AS total_project_budget,
        ROUND(
        CASE WHEN COALESCE(e.total_employees, 0)=0
        THEN 0
        ELSE  COALESCE(p.total_budget, 0)::numeric/e.total_employees
        END, 2
        ) AS budget_per_employee
FROM departments6 d
LEFT JOIN (
    SELECT dept_id,
           COUNT(*) AS total_employees,
           AVG(salary) AS avg_salary
    FROM employees6 e
    GROUP BY dept_id
) e ON e.dept_id=d.dept_id
LEFT JOIN (
    SELECT dept_id,
           COUNT(*) AS total_projects,
           SUM(budget) AS total_budget
    FROM projects6
    GROUP BY dept_id
) p ON p.dept_id=d.dept_id;

--8.2
ALTER TABLE projects6
ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
    SELECT
        p.project_name,
        p.budget,
        d.dept_name,
        p.created_date,
        CASE
            WHEN p.budget > 150000 THEN 'Critical Review Required'
            WHEN p.budget > 100000 THEN 'Management Approval Needed'
            ELSE 'Standard Process'
        END AS apporval_status
FROM projects6 p
JOIN departments6 d ON d.dept_id=p.dept_id
WHERE budget >75000;

--8.3
DO $$BEGIN
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

GRANT USAGE ON SCHEMA public TO viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

GRANT viewer_role TO entry_role;
GRANT INSERT ON TABLE employees6, projects6 TO entry_role;

GRANT entry_role TO analyst_role;
GRANT UPDATE ON TABLE employees6, projects6 TO analyst_role;

GRANT analyst_role TO manager_role;
GRANT DELETE ON TABLE employees6, projects6 TO manager_role;

DO $$BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='alise') THEN
        CREATE USER alise WITH PASSWORD 'alice123';
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='bob') THEN
        CREATE USER bob WITH PASSWORD 'bob123';
    end if;
    IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='charlie') THEN
        CREATE USER charlie WITH PASSWORD 'charlie123';
    end if;
end$$;

GRANT viewer_role TO alise;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;