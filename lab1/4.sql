CREATE SCHEMA IF NOT EXISTS lab1;
SET search_path TO lab1;

    -- 4.1 StudentProject (3NF)
CREATE TABLE IF NOT EXISTS StudentN (
  StudentID INT PRIMARY KEY,
  StudentName VARCHAR(100),
  StudentMajor VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS Supervisor (
  SupervisorID INT PRIMARY KEY,
  SupervisorName VARCHAR(100),
  SupervisorDept VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS Project (
  ProjectID INT PRIMARY KEY,
  ProjectTitle VARCHAR(100),
  ProjectType VARCHAR(50),
  SupervisorID INT REFERENCES Supervisor(SupervisorID)
);
CREATE TABLE IF NOT EXISTS StudentProject (
  StudentID INT REFERENCES StudentN(StudentID),
  ProjectID INT REFERENCES Project(ProjectID),
  Role VARCHAR(50),
  HoursWorked INT,
  StartDate DATE,
  EndDate DATE,
  PRIMARY KEY (StudentID, ProjectID)
);

-- 4.2 CourseSchedule (BCNF)
CREATE TABLE IF NOT EXISTS StudentCS (
  StudentID INT PRIMARY KEY,
  StudentMajor VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS CourseCS (
  CourseID INT PRIMARY KEY,
  CourseName VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS InstructorCS (
  InstructorID INT PRIMARY KEY,
  InstructorName VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS RoomCS (
  Room VARCHAR(20) PRIMARY KEY,
  Building VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS CourseSchedule (
  StudentID INT REFERENCES StudentCS(StudentID),
  CourseID INT  REFERENCES CourseCS(CourseID),
  InstructorID INT REFERENCES InstructorCS(InstructorID),
  TimeSlot VARCHAR(20),
  Room VARCHAR(20) REFERENCES RoomCS(Room),
  PRIMARY KEY (StudentID, CourseID, TimeSlot, Room)
);
