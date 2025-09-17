CREATE SCHEMA IF NOT EXISTS lab1;
SET search_path TO lab1;

CREATE TABLE IF NOT EXISTS Patient (
  PatientID INT PRIMARY KEY,
  Name VARCHAR(50),
  BirthDate DATE,
  Street VARCHAR(100), City VARCHAR(50), State VARCHAR(50), ZipCode VARCHAR(10),
  Insurance VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS PatientPhone (
  PatientID INT REFERENCES Patient(PatientID),
  Phone VARCHAR(20),
  PRIMARY KEY (PatientID, Phone)
);

CREATE TABLE IF NOT EXISTS Doctor (
  DoctorID INT PRIMARY KEY,
  Name VARCHAR(50),
  Phone VARCHAR(20),
  OfficeLocation VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Specialization (
  DoctorID INT REFERENCES Doctor(DoctorID),
  Specialization VARCHAR(50),
  PRIMARY KEY (DoctorID, Specialization)
);

CREATE TABLE IF NOT EXISTS DepartmentHospital (
  DeptCode VARCHAR(10) PRIMARY KEY,
  DeptName VARCHAR(50),
  Location VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Room (
  DeptCode VARCHAR(10) REFERENCES DepartmentHospital(DeptCode),
  RoomNumber VARCHAR(10),
  PRIMARY KEY (DeptCode, RoomNumber)
);

CREATE TABLE IF NOT EXISTS Appointment (
  PatientID INT REFERENCES Patient(PatientID),
  DoctorID  INT REFERENCES Doctor(DoctorID),
  DateTime TIMESTAMP,
  Purpose VARCHAR(200),
  Notes TEXT,
  PRIMARY KEY (PatientID, DoctorID, DateTime)
);

CREATE TABLE IF NOT EXISTS Prescription (
  PatientID INT REFERENCES Patient(PatientID),
  DoctorID  INT REFERENCES Doctor(DoctorID),
  Medication VARCHAR(50),
  Dosage VARCHAR(50),
  Instructions TEXT,
  PRIMARY KEY (PatientID, DoctorID, Medication)
);