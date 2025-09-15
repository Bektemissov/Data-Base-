CREATE TABLE Student (
    StudentID INT PRIMARY KEY,
    StudentName VARCHAR(100),
    StudentMajor VARCHAR(100)
);


CREATE TABLE Supervisor (
    SupervisorID INT PRIMARY KEY,
    SupervisorName VARCHAR(100),
    SupervisorDept VARCHAR(100)
);


CREATE TABLE Project (
    ProjectID INT PRIMARY KEY,
    ProjectTitle VARCHAR(100),
    ProjectType VARCHAR(50),
    SupervisorID INT,
    FOREIGN KEY (SupervisorID) REFERENCES Supervisor(SupervisorID)
);


CREATE TABLE StudentProject (
    StudentID INT,
    ProjectID INT,
    Role VARCHAR(50),
    HoursWorked INT,
    StartDate DATE,
    EndDate DATE,
    PRIMARY KEY (StudentID, ProjectID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (ProjectID) REFERENCES Project(ProjectID)
);

CREATE TABLE Student (
    StudentID INT PRIMARY KEY,
    StudentMajor VARCHAR(100)
);


CREATE TABLE Course (
    CourseID INT PRIMARY KEY,
    CourseName VARCHAR(100)
);


CREATE TABLE Instructor (
    InstructorID INT PRIMARY KEY,
    InstructorName VARCHAR(100)
);


CREATE TABLE Room (
    Room VARCHAR(20) PRIMARY KEY,
    Building VARCHAR(100)
);


CREATE TABLE CourseSchedule (
    StudentID INT,
    CourseID INT,
    InstructorID INT,
    TimeSlot VARCHAR(20),
    Room VARCHAR(20),
    PRIMARY KEY (StudentID, CourseID, TimeSlot, Room),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID),
    FOREIGN KEY (Room) REFERENCES Room(Room)
);