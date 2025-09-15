CREATE TABLE Employee (
    EmpID INT PRIMARY KEY,
    SSN VARCHAR(11) UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(20) UNIQUE,
    Name VARCHAR(50),
    Department VARCHAR(50),
    Salary DECIMAL(10,2)
);


CREATE TABLE Registration (
    StudentID INT,
    CourseCode VARCHAR(20),
    Section VARCHAR(10),
    Semester VARCHAR(10),
    Year INT,
    Grade CHAR(2),
    Credits INT,
    PRIMARY KEY (StudentID, CourseCode, Section, Semester, Year)
);

CREATE TABLE Student (
    StudentID INT PRIMARY KEY,
    Name VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    Major VARCHAR(50),
    AdvisorID INT
);

CREATE TABLE Professor (
    ProfID INT PRIMARY KEY,
    Name VARCHAR(50),
    Department VARCHAR(50),
    Salary DECIMAL(10,2)
);

CREATE TABLE Department (
    DeptCode VARCHAR(10) PRIMARY KEY,
    DeptName VARCHAR(50),
    Budget DECIMAL(12,2),
    ChairID INT
);

CREATE TABLE Course (
    CourseID INT PRIMARY KEY,
    Title VARCHAR(100),
    Credits INT,
    DepartmentCode VARCHAR(10),
    FOREIGN KEY (DepartmentCode) REFERENCES Department(DeptCode)
);

CREATE TABLE Enrollment (
    StudentID INT,
    CourseID INT,
    Semester VARCHAR(10),
    Grade CHAR(2),
    PRIMARY KEY (StudentID, CourseID, Semester),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

ALTER TABLE Student ADD FOREIGN KEY (AdvisorID) REFERENCES Professor(ProfID);
ALTER TABLE Department ADD FOREIGN KEY (ChairID) REFERENCES Professor(ProfID);