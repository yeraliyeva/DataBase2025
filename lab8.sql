drop table if exists projects cascade;
create table departments(
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);
CREATE TABLE employees (
                           emp_id INT PRIMARY KEY,
                           emp_name VARCHAR(100),
                           dept_id INT,
                           salary DECIMAL(10,2),
                           FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
                          proj_id INT PRIMARY KEY,
                          proj_name VARCHAR(100),
                          budget DECIMAL(12,2),
                          dept_id INT,
                          FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
-- Insert sample data
INSERT INTO departments VALUES
                            (101, 'IT', 'Building A'),
                            (102, 'HR', 'Building B'),
                            (103, 'Operations', 'Building C');
INSERT INTO employees VALUES
                          (1, 'John Smith', 101, 50000),
                          (2, 'Jane Doe', 101, 55000),
                          (3, 'Mike Johnson', 102, 48000),
                          (4, 'Sarah Williams', 102, 52000),
                          (5, 'Tom Brown', 103, 60000);
INSERT INTO projects VALUES
                         (201, 'Website Redesign', 75000, 101),
                         (202, 'Database Migration', 120000, 101),
                         (203, 'HR System Upgrade', 50000, 102);
--Part 2: Creating Basic Indexes
--Exercise 2.1: Create a Simple B-tree Index
create index emp_salary on employees(salary);
--Exercise 2.2: Create an Index on a Foreign Key
create index emp_dept_idx on employees(dept_id);
--Exercise 2.3: View Index Information
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--Part 3: Multicolumn Indexes
--Exercise 3.1: Create a Multicolumn Index
create index emp_dept_salary_idx on employees(dept_id,salary);
--Exercise 3.2: Understanding Column Order
create index emp_salary_dept_idx on employees(salary,dept_id);
--Part 4: Unique Indexes
--Exercise 4.1: Create a Unique Index
alter table employees add column email varchar(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;
--create index a unique email
create unique index emp_email_unique_idx on employees(email);
--Exercise 4.2: Unique Index vs UNIQUE Constraint
alter table employees add  column phone varchar(20) unique ;
--Part 5: Indexes and Sorting
--Exercise 5.1: Create an Index for Sorting
create index emp_salary_desc_idx on employees(salary desc);
--: Index with NULL Handling
create index proj_nulls_first_idx on projects(budget nulls first);
--Part 6: Indexes on Expressions
--Exercise 6.1: Create a Function-Based Index
create index emp_name_lower_idx on employees(lower(employees.emp_name));
--index on calculated values
alter table employees add column hire_data date;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;
--managing indexes
alter index emp_salary_idx rename to employees_saalry_index;
--drop unused indexes
drop index emp_salary_dept_idx;
--reindex
reindex index employees_salary_index;
--practical scenarios
select e.emp_name,e.salary,d.dept_name
from employees e
join departments d on e.dept_id = d.dept_id
where e.salary>50000
order by e.salary desc;
--partial index
create index proj_high_budget_idx on projects(budget)
where budget>80000;
--analyze index usage
explain select * from employees where salary>52000;
--index types comparison
--create a hash index
create index dept_name_hash_idx on departments using hash(dept_name);
--compare index types
create index proj_name_btree_idx on projects(proj_name);
create index proj_name_hash_idx on projects using hash(proj_name);
--part 10 cleanup and best practices
--review all indexes
select schemaname,tablename,indexname,pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
from pg_indexes
where schemaname='public'
order by tablename,indexname;
--drop unnecessary indexes
drop index if exists proj_name_hash_idx;
--document your indexes
create view index_documentation as
    select tablename,indexname,indexdef, 'Improves salary-based queries' as purpose
from pg_indexes
where schemaname='public'
and indexname like '%salary%';
select * from index_documentation;
--summary questions
-- 1.b-tree
-- 2. when in column is used where conditions
-- join opertions between drop tables
-- when queries ofen used order by and group by on that column;
-- 3. on small tables ,on columns are frequently deleted,updated,inserted
-- 4.postgresql automatically updates indexes,which make operation slightly slowly
-- 5.explain index ___;