
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);


CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC CHECK (regular_price > 0),
    discount_price NUMERIC CHECK (discount_price > 0 AND discount_price < regular_price),
    CONSTRAINT valid_discount CHECK (discount_price < regular_price)
);


CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);


-- Valid Data
INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES (1, 'John', 'Doe', 30, 50000);

-- Invalid Data (Age out of range)
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary)
-- VALUES (2, 'Jane', 'Smith', 17, 60000); -- Age must be between 18 and 65

-- Invalid Data (Salary <= 0)
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary)
-- VALUES (3, 'Alex', 'Taylor', 25, -1000); -- Salary must be greater than 0

-- 2


CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);


CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);


-- Valid Data
INSERT INTO customers (customer_id, email, registration_date)
VALUES (1, 'customer@example.com', CURRENT_DATE);

-- Invalid Data (Missing NOT NULL field)
-- INSERT INTO customers (customer_id, phone, registration_date)
-- VALUES (2, '1234567890', CURRENT_DATE); -- Email is required

--  3

CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);


CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);


ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username),
ADD CONSTRAINT unique_email UNIQUE (email);

--  4:


CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

-- Insert Valid Data
INSERT INTO departments (dept_id, dept_name, location)
VALUES (1, 'HR', 'Building A');

-- Invalid Data (Duplicate dept_id)
-- INSERT INTO departments (dept_id, dept_name, location)
-- VALUES (1, 'Finance', 'Building B'); -- dept_id must be unique

-- Invalid Data (NULL dept_id)
-- INSERT INTO departments (dept_id, dept_name, location)
-- VALUES (NULL, 'IT', 'Building C'); -- dept_id cannot be NULL

-
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);



--5


CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Valid Data
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (1, 'John Doe', 1, CURRENT_DATE);

-- Invalid Data (Non-existent dept_id)
-- INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
-- VALUES (2, 'Jane Smith', 999, CURRENT_DATE); -- dept_id must exist in departments


CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);


CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk,
    quantity INTEGER CHECK (quantity > 0)
);

-- Try deleting a category with products
-- DELETE FROM categories WHERE category_id = 1; -- Should fail due to RESTRICT

-- Delete an order and see automatic deletion of order_items
-- DELETE FROM orders WHERE order_id = 1; -- Should cascade delete corresponding items

-- 6


CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders,
    product_id INTEGER REFERENCES products,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);
