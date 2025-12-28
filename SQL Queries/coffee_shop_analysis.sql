-----------------------------------------
-- Coffee Shop Retail Sales Analysis - MS SQL Server
-----------------------------------------

-- Create Database
CREATE DATABASE CoffeeSales;
GO

-- Use CoffeeSales
USE CoffeeSales;
GO

-- Create table 
CREATE TABLE SalesData (
    transaction_id INT NOT NULL PRIMARY KEY,
    transaction_date DATE,
    transaction_time TIME,
    transaction_qty INT,
    store_id INT,
    store_location VARCHAR(30),
    product_id INT,
    unit_price FLOAT,
    product_type VARCHAR(30),
    product_detail VARCHAR(50),
    product_category VARCHAR(30)
);
GO
    
-- Import csv file
BULK INSERT SalesData
FROM 'C:\data\Coffee Shop Sales(Transactions).csv'
WITH (
    FIRSTROW = 2,              -- header skip
    FIELDTERMINATOR = ',',     -- CSV separator
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO
    
-- Table structure reference
EXEC sp_help 'SalesData';
GO
    
  -- Data Validation Checks

-- Total rows loaded
SELECT COUNT(*) AS total_rows
FROM SalesData;
GO
    
-- Sample data check
SELECT TOP 100 *
FROM SalesData;
GO

-- Primary key NULL check
SELECT COUNT(*) AS null_ids
FROM SalesData
WHERE transaction_id IS NULL;
GO

-- Sales Performance KPIs

    -- Measures overall revenue, transactions, quantity sold, and average order value
SELECT  
        --total revenue
        ROUND(SUM(transaction_qty*unit_price),2) AS total_revenue, 
        --total transactions
        COUNT(*) AS total_transactions, 
        --total quantity sold generally
        SUM(transaction_qty) AS total_quantity,
        --average revenue per transaction
        ROUND(SUM(transaction_qty * unit_price) / COUNT(transaction_id), 2) AS average_order_value 
FROM SalesData;
