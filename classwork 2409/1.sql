-- 1
DROP DATABASE IF EXISTS library_system;
CREATE DATABASE library_system
  TEMPLATE template0
  ENCODING 'UTF8'
  CONNECTION LIMIT 75;

-- 2
DROP TABLESPACE IF EXISTS digital_content;
CREATE TABLESPACE digital_content LOCATION '/storage/ebooks';


-- table book_catalog
DROP TABLE IF EXISTS book_catalog CASCADE;
CREATE TABLE book_catalog(
  catalog_id SERIAL PRIMARY KEY,
  isbn CHAR(13),
  book_title VARCHAR(150),
  author_name VARCHAR(100),
  publisher VARCHAR(80),
  publication_year SMALLINT,
  total_pages INT,
  book_format CHAR(10),
  purchase_price NUMERIC(10,2),
  is_available BOOLEAN
);

-- table digital_downloads
DROP TABLE IF EXISTS digital_downloads CASCADE;
CREATE TABLE digital_downloads(
  download_id SERIAL PRIMARY KEY,
  user_id INT,
  catalog_id INT,
  download_timestamp TIMESTAMP,
  file_format VARCHAR(10),
  file_size_mb REAL,
  download_completed BOOLEAN,
  expiry_date DATE,
  access_count SMALLINT
);


-- modify book_catalog
ALTER TABLE book_catalog
  ADD COLUMN genre VARCHAR(50),
  ADD COLUMN library_section CHAR(3);

ALTER TABLE book_catalog
  ALTER COLUMN genre SET DEFAULT 'UNKNOWN';

-- modify digital_downloads
ALTER TABLE digital_downloads
  ADD COLUMN device_type VARCHAR(30),
  ADD COLUMN last_accessed TIMESTAMPTZ;

ALTER TABLE digital_downloads
  ALTER COLUMN file_size_mb TYPE INT;

-- 5 reading_sessions
DROP TABLE IF EXISTS reading_sessions CASCADE;
CREATE TABLE reading_sessions(
  session_id SERIAL PRIMARY KEY,
  user_id INT,
  book_id INT,
  session_start TIMESTAMPTZ,
  reading_duration INTERVAL,
  pages_read SMALLINT,
  session_active BOOLEAN
);

--проверки

SELECT table_name
FROM information_schema.tables
WHERE table_schema='public'
ORDER BY 1;


SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name='book_catalog';


SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name='digital_downloads';
