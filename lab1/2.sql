CREATE TABLE Patient (
    PatientID INT PRIMARY KEY,
    Name VARCHAR(50),
    BirthDate DATE,
    Street VARCHAR(100),
    City VARCHAR(50),
    State VARCHAR(50),
    ZipCode VARCHAR(10),
    Insurance VARCHAR(50)
);

CREATE TABLE PatientPhone (
    PatientID INT,
    Phone VARCHAR(20),
    PRIMARY KEY (PatientID, Phone),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
);

CREATE TABLE Doctor (
    DoctorID INT PRIMARY KEY,
    Name VARCHAR(50),
    Phone VARCHAR(20),
    OfficeLocation VARCHAR(100)
);

CREATE TABLE Specialization (
    DoctorID INT,
    Specialization VARCHAR(50),
    PRIMARY KEY (DoctorID, Specialization),
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID)
);

CREATE TABLE DepartmentHospital (
    DeptCode VARCHAR(10) PRIMARY KEY,
    DeptName VARCHAR(50),
    Location VARCHAR(50)
);

CREATE TABLE Room (
    DeptCode VARCHAR(10),
    RoomNumber VARCHAR(10),
    PRIMARY KEY (DeptCode, RoomNumber),
    FOREIGN KEY (DeptCode) REFERENCES DepartmentHospital(DeptCode)
);

CREATE TABLE Appointment (
    PatientID INT,
    DoctorID INT,
    DateTime TIMESTAMP,
    Purpose VARCHAR(200),
    Notes TEXT,
    PRIMARY KEY (PatientID, DoctorID, DateTime),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID)
);

CREATE TABLE Prescription (
    PatientID INT,
    DoctorID INT,
    Medication VARCHAR(50),
    Dosage VARCHAR(50),
    Instructions TEXT,
    PRIMARY KEY (PatientID, DoctorID, Medication),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES Doctor(DoctorID)
);

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(50),
    BillingAddress VARCHAR(100)
);

CREATE TABLE Vendor (
    VendorID INT PRIMARY KEY,
    VendorName VARCHAR(50)
);

CREATE TABLE Category (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50)
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    Name VARCHAR(50),
    Price DECIMAL(10,2),
    InventoryLevel INT
);

CREATE TABLE ProductCategory (
    ProductID INT,
    CategoryID INT,
    PRIMARY KEY (ProductID, CategoryID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
);

CREATE TABLE Supply (
    ProductID INT,
    VendorID INT,
    PRIMARY KEY (ProductID, VendorID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (VendorID) REFERENCES Vendor(VendorID)
);

CREATE TABLE OrderTable (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    ShippingAddress VARCHAR(100),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

CREATE TABLE OrderItem (
    OrderID INT,
    ProductID INT,
    Quantity INT,
    PriceAtOrder DECIMAL(10,2),
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES OrderTable(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

CREATE TABLE Review (
    ReviewID INT PRIMARY KEY,
    ProductID INT,
    CustomerID INT,
    Rating INT,
    Comment TEXT,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);