/* ===========================================================
   LabWork 5 — Database Constraints (PostgreSQL, DataGrip)
   Student: Bektemissov Iskander | ID: 24B031706
   =========================================================== */


DROP TABLE IF EXISTS order_details_ec CASCADE;
DROP TABLE IF EXISTS orders_ec CASCADE;
DROP TABLE IF EXISTS products_ec CASCADE;
DROP TABLE IF EXISTS customers_ec CASCADE;

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS authors CASCADE;

DROP TABLE IF EXISTS employees_dept CASCADE;
DROP TABLE IF EXISTS student_courses CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS course_enrollments CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS products_catalog CASCADE;
DROP TABLE IF EXISTS employees CASCADE;


/* ========================== PART 1: CHECK =============================== */

-- 1.1 Basic CHECK: employees
CREATE TABLE employees (
  employee_id  INTEGER,
  first_name   TEXT,
  last_name    TEXT,
  age          INTEGER CHECK (age BETWEEN 18 AND 65),
  salary       NUMERIC CHECK (salary > 0)
);

-- valid
INSERT INTO employees VALUES (1,'John','Smith', 30, 50000);
INSERT INTO employees VALUES (2,'Sarah','Lee',  65, 90000);

-- invalid (раскомментируй по одной, чтобы увидеть сообщение об ошибке)
-- INSERT INTO employees VALUES (3,'Too','Young', 17, 30000);   -- violates CHECK (age)
-- INSERT INTO employees VALUES (4,'Bad','Salary', 25, -10);    -- violates CHECK (salary)

-- 1.2 Named CHECK: products_catalog.valid_discount
CREATE TABLE products_catalog (
  product_id     INTEGER,
  product_name   TEXT,
  regular_price  NUMERIC,
  discount_price NUMERIC,
  CONSTRAINT valid_discount CHECK (
    regular_price > 0
    AND discount_price > 0
    AND discount_price < regular_price
  )
);

-- valid
INSERT INTO products_catalog VALUES (1,'Headphones', 120.00, 79.99);
INSERT INTO products_catalog VALUES (2,'Mouse',       35.00, 19.99);

-- invalid
-- INSERT INTO products_catalog VALUES (3,'Zero', 0, 1);            -- regular_price > 0
-- INSERT INTO products_catalog VALUES (4,'Negative', 50, -5);      -- discount_price > 0
-- INSERT INTO products_catalog VALUES (5,'BadRatio', 50, 60);      -- discount_price < regular_price

-- 1.3 Multi-column CHECK: bookings
CREATE TABLE bookings (
  booking_id     INTEGER,
  check_in_date  DATE,
  check_out_date DATE,
  num_guests     INTEGER,
  CONSTRAINT chk_guests CHECK (num_guests BETWEEN 1 AND 10),
  CONSTRAINT chk_dates  CHECK (check_out_date > check_in_date)
);

-- valid
INSERT INTO bookings VALUES (101, DATE '2025-10-20', DATE '2025-10-25', 2);
INSERT INTO bookings VALUES (102, DATE '2025-11-01', DATE '2025-11-02', 1);

-- invalid
-- INSERT INTO bookings VALUES (103, DATE '2025-12-01', DATE '2025-11-30', 2);  -- dates
-- INSERT INTO bookings VALUES (104, DATE '2025-12-01', DATE '2025-12-05', 0);  -- guests


/* ======================== PART 2: NOT NULL ============================== */


-- 2.1 customers: NOT NULL
CREATE TABLE customers (
  customer_id       INTEGER NOT NULL,
  email             TEXT    NOT NULL,
  phone             TEXT,
  registration_date DATE    NOT NULL
);

-- valid
INSERT INTO customers VALUES (1,'a@x.com',NULL, CURRENT_DATE);
INSERT INTO customers VALUES (2,'b@x.com','+1-555', CURRENT_DATE);

-- invalid
-- INSERT INTO customers VALUES (NULL,'c@x.com','', CURRENT_DATE);       -- customer_id
-- INSERT INTO customers VALUES (3,NULL,'', CURRENT_DATE);               -- email
-- INSERT INTO customers VALUES (4,'d@x.com','+1', NULL);                -- registration_date

-- 2.2 inventory: NOT NULL + CHECK
CREATE TABLE inventory (
  item_id      INTEGER NOT NULL,
  item_name    TEXT    NOT NULL,
  quantity     INTEGER NOT NULL CHECK (quantity >= 0),
  unit_price   NUMERIC NOT NULL CHECK (unit_price > 0),
  last_updated TIMESTAMP NOT NULL
);

-- valid
INSERT INTO inventory VALUES (10,'SSD 1TB', 5,  99.99, NOW());
INSERT INTO inventory VALUES (11,'RAM 16GB',12, 45.50, NOW());

-- invalid
-- INSERT INTO inventory VALUES (12,'GPU', -1, 399.00, NOW());  -- quantity >= 0
-- INSERT INTO inventory VALUES (13,'CPU',  2,  0.00,  NOW());  -- unit_price > 0
-- INSERT INTO inventory VALUES (14,NULL,   1,  10.00, NOW());  -- item_name NOT NULL


/* ========================= PART 3: UNIQUE =============================== */


-- 3.1 users: single-column UNIQUE
CREATE TABLE users (
  user_id    INTEGER,
  username   TEXT UNIQUE,
  email      TEXT UNIQUE,
  created_at TIMESTAMP
);

-- valid
INSERT INTO users VALUES (1,'user1','u1@mail.com',NOW());
INSERT INTO users VALUES (2,'user2','u2@mail.com',NOW());

-- invalid
-- INSERT INTO users VALUES (3,'user1','other@mail.com',NOW());  -- username unique
-- INSERT INTO users VALUES (4,'user3','u1@mail.com',NOW());     -- email unique

-- 3.2 course_enrollments: multi-column UNIQUE
CREATE TABLE course_enrollments (
  enrollment_id INTEGER,
  student_id    INTEGER,
  course_code   TEXT,
  semester      TEXT,
  CONSTRAINT uniq_enroll UNIQUE (student_id, course_code, semester)
);

-- valid
INSERT INTO course_enrollments VALUES (1,1001,'DB101','Fall-2025');
INSERT INTO course_enrollments VALUES (2,1001,'DB101','Spring-2026');

-- invalid
-- INSERT INTO course_enrollments VALUES (3,1001,'DB101','Fall-2025'); -- duplicate (student,course,semester)

-- 3.3 Named UNIQUE (ещё раз явно именуем)
ALTER TABLE users
  ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users
  ADD CONSTRAINT unique_email    UNIQUE (email);

-- invalid
-- INSERT INTO users VALUES (5,'user2','other@mail.com',NOW());  -- unique_username
-- INSERT INTO users VALUES (6,'userX','u2@mail.com',NOW());     -- unique_email


/* ======================= PART 4: PRIMARY KEY ============================ */

-- 4.1 departments: PK
CREATE TABLE departments (
  dept_id   INTEGER PRIMARY KEY,
  dept_name TEXT NOT NULL,
  location  TEXT
);

-- valid
INSERT INTO departments VALUES (10,'IT','HQ');
INSERT INTO departments VALUES (20,'HR','HQ');
INSERT INTO departments VALUES (30,'Sales','Remote');

-- invalid
-- INSERT INTO departments VALUES (10,'Duplicate','X');        -- duplicate PK
-- INSERT INTO departments (dept_id,dept_name) VALUES (NULL,'NullKey'); -- PK cannot be NULL

-- 4.2 student_courses: composite PK
CREATE TABLE student_courses (
  student_id      INTEGER,
  course_id       INTEGER,
  enrollment_date DATE,
  grade           TEXT,
  CONSTRAINT pk_student_courses PRIMARY KEY (student_id, course_id)
);

-- valid
INSERT INTO student_courses VALUES (1001, 501, DATE '2025-09-01','A');
INSERT INTO student_courses VALUES (1001, 502, DATE '2025-09-01','B');

-- invalid
-- INSERT INTO student_courses VALUES (1001, 501, DATE '2025-10-01','A-'); -- duplicate composite PK


/* ======================= PART 5: FOREIGN KEY ============================ */


-- 5.1 employees_dept с FK → departments
CREATE TABLE employees_dept (
  emp_id    INTEGER PRIMARY KEY,
  emp_name  TEXT NOT NULL,
  dept_id   INTEGER REFERENCES departments(dept_id),
  hire_date DATE
);

-- valid
INSERT INTO employees_dept VALUES (1,'Alice',10, CURRENT_DATE);
INSERT INTO employees_dept VALUES (2,'Bob',  20, CURRENT_DATE);

-- invalid
-- INSERT INTO employees_dept VALUES (3,'Ghost',999, CURRENT_DATE);  -- FK fails

-- 5.2 authors, publishers, books (FK + UNIQUE isbn)
CREATE TABLE authors (
  author_id   INTEGER PRIMARY KEY,
  author_name TEXT NOT NULL,
  country     TEXT
);

CREATE TABLE publishers (
  publisher_id   INTEGER PRIMARY KEY,
  publisher_name TEXT NOT NULL,
  city           TEXT
);

CREATE TABLE books (
  book_id        INTEGER PRIMARY KEY,
  title          TEXT NOT NULL,
  author_id      INTEGER REFERENCES authors(author_id),
  publisher_id   INTEGER REFERENCES publishers(publisher_id),
  publication_year INTEGER,
  isbn           TEXT UNIQUE
);

INSERT INTO authors VALUES
(1,'Isaac Asimov','USA'),
(2,'Haruki Murakami','Japan'),
(3,'Ursula K. Le Guin','USA');

INSERT INTO publishers VALUES
(1,'Penguin','London'),
(2,'Vintage','New York');

INSERT INTO books VALUES
(100,'Foundation',1,1,1951,'978-0-14-017737-4'),
(101,'Kafka on the Shore',2,2,2002,'978-1-4000-7927-0'),
(102,'A Wizard of Earthsea',3,1,1968,'978-0-14-030477-0');

-- 5.3 ON DELETE: RESTRICT vs CASCADE
CREATE TABLE categories (
  category_id   INTEGER PRIMARY KEY,
  category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
  product_id   INTEGER PRIMARY KEY,
  product_name TEXT NOT NULL,
  category_id  INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
  order_id   INTEGER PRIMARY KEY,
  order_date DATE NOT NULL
);

CREATE TABLE order_items (
  item_id    INTEGER PRIMARY KEY,
  order_id   INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products_fk(product_id),
  quantity   INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1,'Electronics'),(2,'Books');
INSERT INTO products_fk VALUES (100,'E-Reader',2),(200,'Headset',1);
INSERT INTO orders VALUES (500, CURRENT_DATE);
INSERT INTO order_items VALUES (1,500,100,1),(2,500,200,2);

-- RESTRICT (ожидаем ошибку при раскомментировании)
-- DELETE FROM categories WHERE category_id=1;  -- FAIL: referenced by products_fk

-- CASCADE: удалим заказ → его позиции удалятся автоматически
-- SELECT * FROM order_items WHERE order_id=500; -- до
DELETE FROM orders WHERE order_id=500;
-- SELECT * FROM order_items WHERE order_id=500; -- после (пусто)


/* ===================== PART 6: PRACTICAL (E-commerce) =================== */

-- 6.1 Cхема с констрейнтами
CREATE TABLE customers_ec (
  customer_id      INTEGER PRIMARY KEY,
  name             TEXT    NOT NULL,
  email            TEXT    NOT NULL UNIQUE,
  phone            TEXT,
  registration_date DATE   NOT NULL
);

CREATE TABLE products_ec (
  product_id     INTEGER PRIMARY KEY,
  name           TEXT    NOT NULL,
  description    TEXT,
  price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ec (
  order_id     INTEGER PRIMARY KEY,
  customer_id  INTEGER NOT NULL REFERENCES customers_ec(customer_id) ON DELETE RESTRICT,
  order_date   DATE    NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
  status       TEXT    NOT NULL CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details_ec (
  order_detail_id INTEGER PRIMARY KEY,
  order_id        INTEGER NOT NULL REFERENCES orders_ec(order_id)     ON DELETE CASCADE,
  product_id      INTEGER NOT NULL REFERENCES products_ec(product_id) ON DELETE RESTRICT,
  quantity        INTEGER NOT NULL CHECK (quantity > 0),
  unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- 6.2 Данные (≥5 строк на таблицу)
INSERT INTO customers_ec VALUES
(1,'Alice','alice@example.com',NULL, DATE '2025-10-01'),
(2,'Bob','bob@example.com','+1-555', DATE '2025-10-02'),
(3,'Carol','carol@example.com',NULL, DATE '2025-10-03'),
(4,'Dave','dave@example.com','+1-777', DATE '2025-10-04'),
(5,'Eve','eve@example.com',NULL, DATE '2025-10-05');

INSERT INTO products_ec VALUES
(100,'Laptop','14-inch ultrabook', 999.99,  10),
(101,'Mouse','Wireless mouse',       19.99, 200),
(102,'Keyboard','Mechanical',        79.50,  50),
(103,'Monitor','27-inch IPS',       229.00,  25),
(104,'USB-C Cable','1m cable',        7.99, 500);

INSERT INTO orders_ec VALUES
(1000,1, CURRENT_DATE, 0.00,'pending'),
(1001,2, CURRENT_DATE, 0.00,'processing'),
(1002,3, CURRENT_DATE, 0.00,'pending'),
(1003,4, CURRENT_DATE, 0.00,'pending'),
(1004,5, CURRENT_DATE, 0.00,'pending');

INSERT INTO order_details_ec VALUES
(1,1000,100,1, 999.99),
(2,1000,101,2,  19.99),
(3,1001,103,1, 229.00),
(4,1002,102,1,  79.50),
(5,1003,104,5,   7.99);

-- Подтянем total_amount из деталей
UPDATE orders_ec o
SET total_amount = x.sum_amount
FROM (
  SELECT order_id, SUM(quantity*unit_price)::NUMERIC(12,2) AS sum_amount
  FROM order_details_ec GROUP BY order_id
) x
WHERE o.order_id = x.order_id;

-- 6.3 Тесты: успехи / ошибки (раскомментируй по одной)
INSERT INTO customers_ec VALUES (6,'Frank','frank@example.com',NULL,CURRENT_DATE);
INSERT INTO products_ec  VALUES (105,'Webcam','HD webcam', 49.99, 80);
INSERT INTO orders_ec    VALUES (1005,6,CURRENT_DATE, 0.00,'pending');
INSERT INTO order_details_ec VALUES (6,1005,105,2, 49.99);

-- Ошибки:
-- INSERT INTO customers_ec VALUES (7,'Dup','alice@example.com',NULL,CURRENT_DATE); -- UNIQUE email
-- INSERT INTO products_ec VALUES (106,'Bad Price','x', -1.00, 5);   -- CHECK price >= 0
-- INSERT INTO products_ec VALUES (107,'Bad Stock','x', 10.00, -5);  -- CHECK stock >= 0
-- INSERT INTO orders_ec   VALUES (1006,1,CURRENT_DATE,0,'unknown'); -- status IN (...)
-- DELETE FROM products_ec WHERE product_id=105;                     -- RESTRICT: referenced
-- SELECT COUNT(*) FROM order_details_ec WHERE order_id=1005;        -- до
-- DELETE FROM orders_ec WHERE order_id=1005;                        -- CASCADE удалит детали
-- SELECT COUNT(*) FROM order_details_ec WHERE order_id=1005;        -- после (0)

-- Быстрые проверки:
-- SELECT * FROM customers_ec ORDER BY customer_id;
-- SELECT * FROM products_ec ORDER BY product_id;
-- SELECT * FROM orders_ec ORDER BY order_id;
-- SELECT * FROM order_details_ec ORDER BY order_detail_id;