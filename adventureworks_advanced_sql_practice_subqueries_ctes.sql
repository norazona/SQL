-- AdventureWorksDW2022 Advanced SQL Questions - Subqueries and CTEs

-- Subqueries AND CTEs
-- 21.	Find customers whose total purchases exceed the average customer purchase amount.
SELECT
    CustomerKey,
    COUNT(*) AS TotalOrders,
    SUM(SalesAmount) AS TotalPurchases,
    AVG(SalesAmount) AS AvgOrderValue
FROM FactInternetSales
GROUP BY CustomerKey
HAVING SUM(SalesAmount) > (
    SELECT AVG(CustomerTotal)
    FROM (
        SELECT 
            CustomerKey,
            SUM(SalesAmount) AS CustomerTotal
        FROM FactInternetSales
        GROUP BY CustomerKey
    ) AS CustomerTotals
)
ORDER BY TotalPurchases DESC;

-- 22.	List products whose ListPrice is higher than the average ListPrice in their category.
-- First CTE is to join DimProduct with DimProductSubcategory and DimProductCategory
WITH RefinedProducts AS (
    SELECT
        dp.ProductKey AS ProductKey,
        dp.EnglishProductName AS ProductName,
        dpc.ProductCategoryKey AS ProductCategoryKey,
        dpc.EnglishProductCategoryName AS ProductCategory,
        dp.ListPrice AS ListPrice
    FROM DimProduct dp
    INNER JOIN DimProductSubcategory dps
        ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
    INNER JOIN DimProductCategory dpc
        ON dps.ProductCategoryKey = dpc.ProductCategoryKey
    WHERE ListPrice IS NOT NULL
),
-- CTE to get average list price by product category
AvgListPrice AS (
    SELECT
        ProductCategoryKey,
        AVG(ListPrice) AS AvgListPrice
    FROM RefinedProducts
    GROUP BY ProductCategoryKey
)
SELECT 
    ProductKey,
    ProductName,
    alp.ProductCategoryKey,
    ListPrice,
    AvgListPrice
FROM RefinedProducts rp
-- Join the two CTEs together to get table of individual products compared to avg list price for product category
INNER JOIN AvgListPrice alp
    ON rp.ProductCategoryKey = alp.ProductCategoryKey
WHERE ListPrice > AvgListPrice
ORDER BY ProductKey;

-- 23.	Identify the top 5 sales days (by total SalesAmount) and show all transactions from those days.
WITH TopFiveSalesDays AS (
    SELECT TOP 5
        OrderDateKey,
        DATETRUNC(DAY,OrderDate) AS Day,
        SUM(SalesAmount) AS TotalSales
    FROM FactInternetSales
    GROUP BY DATETRUNC(DAY,OrderDate), OrderDateKey
    ORDER BY TotalSales DESC
)
SELECT 
    OrderDateKey,
    OrderDate,
    SalesOrderNumber,
    OrderQuantity,
    UnitPrice,
    SalesAmount,
    TaxAmt,
    Freight,
    ROUND((SalesAmount + TaxAmt + Freight), 2) AS TotalPrice
FROM FactInternetSales 
WHERE OrderDateKey IN (
    SELECT OrderDateKey FROM TopFiveSalesDays
);

