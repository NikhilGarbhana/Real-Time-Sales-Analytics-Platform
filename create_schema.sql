-- Create Customers Table
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Age INT CHECK (Age > 0),
    RegionID INT NOT NULL
);

-- Create Products Table
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),
    Stock INT NOT NULL CHECK (Stock >= 0)
);

-- Create Regions Table
CREATE TABLE Regions (
    RegionID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
    RegionName NVARCHAR(50) NOT NULL
);

-- Create Dates Table
CREATE TABLE Dates (
    DateID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
    Date DATE NOT NULL UNIQUE,
    Month NVARCHAR(20) NOT NULL,
    Year INT NOT NULL,
    Weekday NVARCHAR(20) NOT NULL
);

-- Create SalesFact Table
CREATE TABLE SalesFact (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,  -- Use INT IDENTITY for auto-increment
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    TotalPrice DECIMAL(10, 2),  -- Store the total price as a regular column
    OrderDate DATE NOT NULL,
    RegionID INT NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (RegionID) REFERENCES Regions(RegionID)
);

-- Separate the CREATE TRIGGER statement into its own batch using GO
GO

-- Create the trigger to update TotalPrice on INSERT
CREATE TRIGGER trg_UpdateTotalPrice
ON SalesFact
FOR INSERT
AS
BEGIN
    UPDATE sf
    SET sf.TotalPrice = i.Quantity * p.Price
    FROM SalesFact sf
    INNER JOIN inserted i ON sf.OrderID = i.OrderID
    INNER JOIN Products p ON i.ProductID = p.ProductID;
END;

-- Separate the CREATE TRIGGER statement into its own batch using GO
GO
-- Trigger for UPDATE
CREATE TRIGGER trg_UpdateTotalPriceUpdate
ON SalesFact
FOR UPDATE
AS
BEGIN
    UPDATE sf
    SET sf.TotalPrice = i.Quantity * p.Price
    FROM SalesFact sf
    INNER JOIN inserted i ON sf.OrderID = i.OrderID
    INNER JOIN Products p ON i.ProductID = p.ProductID
    INNER JOIN deleted d ON sf.OrderID = d.OrderID
    WHERE i.Quantity <> d.Quantity OR i.ProductID <> d.ProductID;  -- Only update if changed
END;

