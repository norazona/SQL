-- Section 1: Basic Aggregations & Filtering (AdventureWorksDW2022)

-- 1. Retrieve the total sales amount (SalesAmount) by ProductCategory for the year 2013.
SELECT
	dpc.EnglishProductCategoryName,
	--YEAR(fs.OrderDate) AS Year,
	SUM(SalesAmount) AS TotalSalesAmount
FROM FactInternetSales fs
INNER JOIN DimProduct dp
	ON fs.ProductKey = dp.ProductKey
INNER JOIN DimProductSubcategory dps
	ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
INNER JOIN DimProductCategory dpc
	ON dps.ProductCategoryKey = dpc.ProductCategoryKey
GROUP BY dpc.EnglishProductCategoryName, YEAR(fs.OrderDate)
HAVING YEAR(fs.OrderDate) = 2013;

-- 2. Count the number of orders for each Customer in 2023.
SELECT
	CustomerKey,
	COUNT(SalesOrderNumber) AS TotalOrders
FROM FactInternetSales 
GROUP BY CustomerKey, YEAR(OrderDate)
HAVING YEAR(OrderDate) = 2013
ORDER BY TotalOrders DESC;

-- 3. Find the average SalesAmount per SalesTerritory.
SELECT
	dst.SalesTerritoryCountry,
	AVG(SalesAmount) AS AvgSalesAmount
FROM FactInternetSales fis
INNER JOIN DimSalesTerritory dst
	ON fis.SalesTerritoryKey = dst.SalesTerritoryKey
GROUP BY dst.SalesTerritoryCountry;

-- 4. Identify the top 5 products with the highest TotalSales in 2012.
SELECT TOP 5
	EnglishProductName,
	ROUND(SUM(SalesAmount),2) AS TotalSales
FROM FactInternetSales fis
INNER JOIN DimProduct dp
	ON fis.ProductKey = dp.ProductKey
GROUP BY EnglishProductName
ORDER BY TotalSales DESC;

-- 5. Calculate the total quantity sold (OrderQuantity) for each ProductSubcategory.
SELECT 
	dps.EnglishProductSubcategoryName as ProductSubcategory,
	SUM(OrderQuantity) AS TotalQuantitySold
FROM FactInternetSales fis
INNER JOIN DimProduct dp
	ON fis.ProductKey = dp.ProductKey
INNER JOIN DimProductSubcategory dps
	ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
GROUP BY dps.EnglishProductSubcategoryName;

-- 6. List all SalesOrders where the TaxAmt was greater than $100.
SELECT 
	SalesOrderNumber,
	SalesOrderLineNumber,
	OrderDate,
	OrderQuantity,
	UnitPrice,
	ExtendedAmount,
	UnitPriceDiscountPct,
	DiscountAmount,
	SalesAmount,
	TaxAmt
FROM FactInternetSales
WHERE TaxAmt > 100;

-- 7. Compute the monthly total SalesAmount for 2013.
SELECT 
	DATETRUNC(MONTH,OrderDate) AS YearMonth,
	SUM(SalesAmount) AS TotalSales
FROM FactInternetSales
GROUP BY DATETRUNC(MONTH,OrderDate)
ORDER BY DATETRUNC(MONTH,OrderDate) ASC;

-- 8. Determine the percentage contribution of each ProductCategory to total sales in 2022.
SELECT 
	dps.EnglishProductSubcategoryName as ProductSubcategory,
	SUM(OrderQuantity) AS TotalQuantitySold
FROM FactInternetSales fis
INNER JOIN DimProduct dp
	ON fis.ProductKey = dp.ProductKey
INNER JOIN DimProductSubcategory dps
	ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
GROUP BY dps.EnglishProductSubcategoryName;

-- 9. Find the minimum, maximum, and average UnitPrice for each ProductCategory.
SELECT
	dpc.EnglishProductCategoryName,
	MIN(UnitPrice) AS MinUnitPrice,
	MAX(UnitPrice) AS MaxUnitPrice,
	AVG(UnitPrice) AS AvgUnitPrice
FROM FactInternetSales fis
INNER JOIN DimProduct dp
	ON fis.ProductKey = dp.ProductKey
INNER JOIN DimProductSubcategory dps
	ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
INNER JOIN DimProductCategory dpc
	ON dps.ProductCategoryKey = dpc.ProductCategoryKey
GROUP BY dpc.EnglishProductCategoryName;

-- 10. Count the number of distinct Customers per SalesTerritory.
SELECT
	dst.SalesTerritoryCountry,
	COUNT(CustomerKey) AS Customers
FROM FactInternetSales fis
INNER JOIN DimSalesTerritory dst
	ON fis.SalesTerritoryKey = dst.SalesTerritoryKey
GROUP BY dst.SalesTerritoryCountry;