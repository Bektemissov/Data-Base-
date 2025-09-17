CREATE SCHEMA IF NOT EXISTS lab1;
SET search_path TO lab1;

CREATE TABLE IF NOT EXISTS Employee (
  EmpID INT PRIMARY KEY,
  SSN VARCHAR(11) UNIQUE,
  Email VARCHAR(100) UNIQUE,
  Phone VARCHAR(20) UNIQUE,
  Name VARCHAR(50),
  Department VARCHAR(50),
  Salary DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS Registration (
  StudentID INT,
  CourseCode VARCHAR(20),
  Section VARCHAR(10),
  Semester VARCHAR(10),
  Year INT,
  Grade CHAR(2),
  Credits INT,
  PRIMARY KEY (StudentID, CourseCode, Section, Semester, Year)
);

CREATE TABLE IF NOT EXISTS Student (
  StudentID INT PRIMARY KEY,
  Name VARCHAR(50),
  Email VARCHAR(100) UNIQUE,
  Major VARCHAR(50),
  AdvisorID INT
);

CREATE TABLE IF NOT EXISTS Professor (
  ProfID INT PRIMARY KEY,
  Name VARCHAR(50),
  Department VARCHAR(50),
  Salary DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS Department (
  DeptCode VARCHAR(10) PRIMARY KEY,
  DeptName VARCHAR(50),
  Budget DECIMAL(12,2),
  ChairID INT
);

CREATE TABLE IF NOT EXISTS Course (
  CourseID INT PRIMARY KEY,
  Title VARCHAR(100),
  Credits INT,
  DepartmentCode VARCHAR(10) REFERENCES Department(DeptCode)
);

CREATE TABLE IF NOT EXISTS Enrollment (
  StudentID INT REFERENCES Student(StudentID),
  CourseID INT REFERENCES Course(CourseID),
  Semester VARCHAR(10),
  Grade CHAR(2),
  PRIMARY KEY (StudentID, CourseID, Semester)
);

ALTER TABLE IF EXISTS Student    DROP CONSTRAINT IF EXISTS fk_student_advisor;
ALTER TABLE IF EXISTS Department DROP CONSTRAINT IF EXISTS fk_dept_chair;

ALTER TABLE Student    ADD CONSTRAINT fk_student_advisor FOREIGN KEY (AdvisorID) REFERENCES Professor(ProfID);
ALTER TABLE Department ADD CONSTRAINT fk_dept_chair   FOREIGN KEY (ChairID)   REFERENCES Professor(ProfID);