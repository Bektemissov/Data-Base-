CREATE TABLE Student (
    StudentID INT PRIMARY KEY,
    Name VARCHAR(100),
    Major VARCHAR(100)
);


CREATE TABLE Faculty (
    FacultyID INT PRIMARY KEY,
    Name VARCHAR(100),
    Department VARCHAR(100)
);


CREATE TABLE Club (
    ClubID INT PRIMARY KEY,
    ClubName VARCHAR(100),
    Budget DECIMAL(12,2),
    AdvisorID INT,
    FOREIGN KEY (AdvisorID) REFERENCES Faculty(FacultyID)
);


CREATE TABLE Membership (
    StudentID INT,
    ClubID INT,
    JoinDate DATE,
    Role VARCHAR(50),
    PRIMARY KEY (StudentID, ClubID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (ClubID) REFERENCES Club(ClubID)
);


CREATE TABLE Room (
    RoomID INT PRIMARY KEY,
    Location VARCHAR(100),
    Capacity INT
);


CREATE TABLE Event (
    EventID INT PRIMARY KEY,
    ClubID INT,
    Title VARCHAR(100),
    EventDate DATE,
    RoomID INT,
    FOREIGN KEY (ClubID) REFERENCES Club(ClubID),
    FOREIGN KEY (RoomID) REFERENCES Room(RoomID)
);


CREATE TABLE Attendance (
    StudentID INT,
    EventID INT,
    Status VARCHAR(20),
    PRIMARY KEY (StudentID, EventID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (EventID) REFERENCES Event(EventID)
);


CREATE TABLE Expense (
    ExpenseID INT PRIMARY KEY,
    ClubID INT,
    Amount DECIMAL(10,2),
    Purpose VARCHAR(200),
    ExpenseDate DATE,
    FOREIGN KEY (ClubID) REFERENCES Club(ClubID)
);