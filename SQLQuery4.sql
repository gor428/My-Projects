-- =====================================
-- RESET DATABASE
-- =====================================
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CarRentalDB')
BEGIN
    ALTER DATABASE CarRentalDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CarRentalDB;
END
GO

CREATE DATABASE CarRentalDB;
GO

USE CarRentalDB;
GO

-- =====================================
-- TABLES
-- =====================================

CREATE TABLE customers (
    CustomerID INT IDENTITY PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    DateOfBirth DATE,
    LicenseNumber VARCHAR(30) UNIQUE
);

CREATE TABLE vehicles (
    VehicleID INT IDENTITY PRIMARY KEY,
    LicensePlate VARCHAR(20) UNIQUE,
    Make VARCHAR(50),
    Model VARCHAR(50),
    DailyRate FLOAT,
    Status VARCHAR(20) DEFAULT 'Available'
);

CREATE TABLE rentals (
    RentalID INT IDENTITY PRIMARY KEY,
    CustomerID INT,
    VehicleID INT,
    PickupDate DATETIME,
    ReturnDate DATETIME,
    TotalAmount FLOAT,
    Status VARCHAR(20) DEFAULT 'Scheduled',

    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),
    FOREIGN KEY (VehicleID) REFERENCES vehicles(VehicleID)
);
GO

-- =====================================
-- INSERT CUSTOMERS (50)
-- =====================================
DECLARE @i INT = 1;

WHILE @i <= 50
BEGIN
    INSERT INTO customers (FirstName, LastName, Email, DateOfBirth, LicenseNumber)
    VALUES (
        'Name' + CAST(@i AS VARCHAR),
        'Surname' + CAST(@i AS VARCHAR),
        'user' + CAST(@i AS VARCHAR) + '@mail.com',
        DATEADD(YEAR, -20 - (@i % 10), GETDATE()),
        'DL' + RIGHT('000' + CAST(@i AS VARCHAR), 3)
    );

    SET @i = @i + 1;
END;
GO

-- =====================================
-- INSERT VEHICLES (50)
-- =====================================
DECLARE @i INT = 1;

WHILE @i <= 50
BEGIN
    INSERT INTO vehicles (LicensePlate, Make, Model, DailyRate, Status)
    VALUES (
        'CAR' + RIGHT('000' + CAST(@i AS VARCHAR), 3),
        CASE 
            WHEN @i % 5 = 0 THEN 'BMW'
            WHEN @i % 5 = 1 THEN 'Toyota'
            WHEN @i % 5 = 2 THEN 'Ford'
            WHEN @i % 5 = 3 THEN 'Mercedes'
            ELSE 'Honda'
        END,
        'Model' + CAST(@i AS VARCHAR),
        40 + (@i * 2),
        'Available'
    );

    SET @i = @i + 1;
END;
GO

-- =====================================
-- INSERT RENTALS (100)
-- =====================================
DECLARE @i INT = 1;

WHILE @i <= 100
BEGIN
    INSERT INTO rentals (CustomerID, VehicleID, PickupDate, ReturnDate, TotalAmount, Status)
    VALUES (
        (ABS(CHECKSUM(NEWID())) % 50) + 1,
        (ABS(CHECKSUM(NEWID())) % 50) + 1,
        DATEADD(DAY, -@i, GETDATE()),
        DATEADD(DAY, -@i + 3, GETDATE()),
        100 + (@i * 5),
        'Completed'
    );

    SET @i = @i + 1;
END;
GO

-- =====================================
-- STORED PROCEDURES
-- =====================================

CREATE PROCEDURE sp_get_available_vehicles
AS
BEGIN
    SELECT * FROM vehicles WHERE Status = 'Available';
END;
GO

CREATE PROCEDURE sp_add_customer
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Email VARCHAR(100),
    @DOB DATE,
    @License VARCHAR(30)
AS
BEGIN
    INSERT INTO customers (FirstName, LastName, Email, DateOfBirth, LicenseNumber)
    VALUES (@FirstName, @LastName, @Email, @DOB, @License);
END;
GO

CREATE PROCEDURE sp_rent_car
    @CustomerID INT,
    @VehicleID INT
AS
BEGIN
    INSERT INTO rentals (CustomerID, VehicleID, PickupDate, Status)
    VALUES (@CustomerID, @VehicleID, GETDATE(), 'Active');

    UPDATE vehicles
    SET Status = 'Rented'
    WHERE VehicleID = @VehicleID;
END;
GO

CREATE PROCEDURE sp_complete_rental
    @RentalID INT
AS
BEGIN
    UPDATE rentals
    SET ReturnDate = GETDATE(),
        Status = 'Completed',
        TotalAmount = DATEDIFF(DAY, PickupDate, GETDATE()) * 50
    WHERE RentalID = @RentalID;

    UPDATE vehicles
    SET Status = 'Available'
    WHERE VehicleID = (
        SELECT VehicleID FROM rentals WHERE RentalID = @RentalID
    );
END;
GO

-- =====================================
-- TEST OUTPUT
-- =====================================

PRINT '===== CUSTOMERS TABLE =====';
SELECT * FROM customers;

PRINT '===== VEHICLES TABLE =====';
SELECT * FROM vehicles;

PRINT '===== RENTALS TABLE =====';
SELECT * FROM rentals;

PRINT 'Available Vehicles:';
EXEC sp_get_available_vehicles;

