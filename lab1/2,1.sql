CREATE SCHEMA IF NOT EXISTS lab1;
SET search_path TO lab1;

CREATE TABLE IF NOT EXISTS Customer (
  CustomerID INT PRIMARY KEY,
  Name VARCHAR(50),
  BillingAddress VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS Vendor (
  VendorID INT PRIMARY KEY,
  VendorName VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Category (
  CategoryID INT PRIMARY KEY,
  CategoryName VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Product (
  ProductID INT PRIMARY KEY,
  Name VARCHAR(50),
  Price DECIMAL(10,2),
  InventoryLevel INT
);

CREATE TABLE IF NOT EXISTS ProductCategory (
  ProductID INT REFERENCES Product(ProductID),
  CategoryID INT REFERENCES Category(CategoryID),
  PRIMARY KEY (ProductID, CategoryID)
);

CREATE TABLE IF NOT EXISTS Supply (
  ProductID INT REFERENCES Product(ProductID),
  VendorID INT  REFERENCES Vendor(VendorID),
  PRIMARY KEY (ProductID, VendorID)
);

CREATE TABLE IF NOT EXISTS OrderTable (
  OrderID INT PRIMARY KEY,
  CustomerID INT REFERENCES Customer(CustomerID),
  OrderDate DATE,
  ShippingAddress VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS OrderItem (
  OrderID INT REFERENCES OrderTable(OrderID),
  ProductID INT REFERENCES Product(ProductID),
  Quantity INT,
  PriceAtOrder DECIMAL(10,2),
  PRIMARY KEY (OrderID, ProductID)
);

CREATE TABLE IF NOT EXISTS Review (
  ReviewID INT PRIMARY KEY,
  ProductID INT REFERENCES Product(ProductID),
  CustomerID INT REFERENCES Customer(CustomerID),
  Rating INT,
  Comment TEXT
);
