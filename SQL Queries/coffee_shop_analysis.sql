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

--Time Based KPIs

        --Total sales per month
SELECT 
    DATENAME(MONTH, transaction_date) AS month,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_sales
FROM SalesData
GROUP BY DATENAME(MONTH, transaction_date)
ORDER BY MIN(MONTH(transaction_date));


        --top month with highest sales
SELECT TOP 1 
    DATENAME(MONTH, transaction_date) as MONTH,
    ROUND(SUM(transaction_qty*unit_price),2) AS total_sales
FROM SalesData
GROUP BY DATENAME(MONTH, transaction_date)
ORDER BY total_sales DESC;

        --top month with lowest sales
SELECT TOP 1 
    DATENAME(MONTH, transaction_date) as MONTH,
    ROUND(SUM(transaction_qty*unit_price),2) AS total_sales
FROM SalesData
GROUP BY DATENAME(MONTH, transaction_date)
ORDER BY total_sales;
        
        --total sales per day
SELECT DATENAME(WEEKDAY, transaction_date) AS Day,
ROUND(SUM(transaction_qty*unit_price),2) AS total_sales
FROM SalesData
GROUP BY DATENAME(WEEKDAY, transaction_date)
ORDER BY total_sales;

        --days with highest & lowest sales
SELECT * FROM
    --highest day
    (SELECT TOP 1
    DATENAME(WEEKDAY, transaction_date) AS Day,
    ROUND(SUM(transaction_qty*unit_price),2) AS total_sales
    FROM SalesData
    GROUP BY DATENAME(WEEKDAY, transaction_date)
    ORDER BY total_sales DESC) AS highest_day
UNION ALL
SELECT * FROM
    --lowest day
    (SELECT TOP 1
    DATENAME(WEEKDAY, transaction_date) AS Day,
    ROUND(SUM(transaction_qty*unit_price),2) AS total_sales
    FROM SalesData
    GROUP BY DATENAME(WEEKDAY, transaction_date)
    ORDER BY total_sales) AS Lowest_day;

        -- Second highest sales day
SELECT day, total_sales
FROM 
(
        SELECT 
            DATENAME(WEEKDAY, transaction_date) AS day,
            ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales,
            DENSE_RANK() OVER (ORDER BY SUM(transaction_qty * unit_price) DESC) AS sales_rank
        FROM SalesData
        GROUP BY DATENAME(WEEKDAY, transaction_date)
) t
WHERE sales_rank = 2;

        --Weekday and Weekend sales
SELECT 
    CASE 
        WHEN DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM SalesData
GROUP BY 
    CASE 
        WHEN DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday')THEN 'Weekend'
        ELSE 'Weekday'
    END;

        --total sales per hour
SELECT 
    DATEPART(HOUR, transaction_time) AS hour,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM SalesData
GROUP BY DATEPART(HOUR, transaction_time)
ORDER BY DATEPART(HOUR, transaction_time);


--Product type and category KPIs

        --total sales for each product
SELECT  product_type,
        ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM SalesData
GROUP BY product_type
ORDER BY ROUND(SUM(transaction_qty * unit_price), 2) DESC;

        --total sales product category-wise
SELECT
    product_type,
    product_category,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM SalesData
GROUP BY
    product_category,
    product_type
ORDER BY
    total_sales DESC;

        --top product for each hour
 WITH HourlySales AS (
    SELECT
        DATEPART(HOUR, transaction_time) AS hour,
        product_category,
        product_type,
        SUM(transaction_qty * unit_price) AS total_sales
    FROM SalesData
    WHERE transaction_time IS NOT NULL
    GROUP BY
        DATEPART(HOUR, transaction_time),
        product_category,
        product_type
),
RankedSales AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY hour ORDER BY total_sales DESC) AS rnk
    FROM HourlySales
)
SELECT
    hour,
    product_category,
    product_type,
    ROUND(total_sales, 2) AS total_sales
FROM RankedSales
WHERE rnk = 1
ORDER BY hour;

--Store performance KPIs

    -- Store-wise total sales
SELECT
    store_location,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM SalesData
GROUP BY store_location
ORDER BY total_sales DESC;

    --top product of each store
WITH StoreProductSales AS (
    SELECT
        store_location,
        product_category,
        product_type,
        SUM(transaction_qty * unit_price) AS total_sales
    FROM SalesData
    GROUP BY
        store_location,
        product_category,
        product_type
),
RankedProducts AS (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY store_location
               ORDER BY total_sales DESC
           ) AS rnk
    FROM StoreProductSales
)
SELECT
    store_location,
    product_category,
    product_type,
    ROUND(total_sales, 2) AS total_sales
FROM RankedProducts
WHERE rnk = 1
ORDER BY store_location;

