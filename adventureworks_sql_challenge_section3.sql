-- Section 3: CTEs & Advanced Filtering

-- Use a CTE to calculate total sales per Customer and then find the top 10 customers.
WITH customer_total_sales AS (
	SELECT 
		c.CustomerKey,
		CONCAT(c.FirstName, ' ', c.LastName) AS Name,
		SUM(SalesAmount) AS TotalSales
	FROM FactInternetSales s
	INNER JOIN DimCustomer c
		ON s.CustomerKey = c.CustomerKey
	GROUP BY 
		c.CustomerKey,
		CONCAT(c.FirstName, ' ', c.LastName)
)
SELECT TOP 10
	Name,
	TotalSales
FROM customer_total_sales
ORDER BY TotalSales DESC;

-- Create a CTE that calculates monthly sales growth per ProductCategory.
WITH monthly_sales AS (
	SELECT 
		pc.EnglishProductCategoryName AS ProductCategory,
		DATETRUNC(MONTH,s.OrderDate) AS YearMonth,
		SUM(SalesAmount) AS TotalSales
	FROM FactInternetSales s
	INNER JOIN DimProduct p
		ON s.ProductKey = p.ProductKey
	INNER JOIN DimProductSubcategory psc
		ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
	INNER JOIN DimProductCategory pc
		ON psc.ProductCategoryKey = pc.ProductCategoryKey
	GROUP BY 
		pc.EnglishProductCategoryName,
		DATETRUNC(MONTH,s.OrderDate)
)
SELECT 
	YearMonth,
	ProductCategory,
	TotalSales,
	LAG(TotalSales) OVER (PARTITION BY ProductCategory ORDER BY YearMonth) AS PreviousMonthSales,
	TotalSales - LAG(TotalSales) OVER (PARTITION BY ProductCategory ORDER BY YearMonth) AS SalesDifference,
	((TotalSales - LAG(TotalSales) OVER (PARTITION BY ProductCategory ORDER BY YearMonth)) / 
		LAG(TotalSales) OVER (PARTITION BY ProductCategory ORDER BY YearMonth)) * 100 AS MoMChange
FROM monthly_sales
ORDER BY 
	ProductCategory ASC,
	YearMonth ASC

-- Using a CTE, list products with sales higher than the average product sales.
WITH product_sales AS (
	-- Total Sales By Product
	SELECT 
		p.ProductKey AS ProductKey,
		p.EnglishDescription AS ProductName,
		SUM(SalesAmount) AS TotalSales
	FROM FactInternetSales s
	INNER JOIN DimProduct p
		ON s.ProductKey = p.ProductKey
	GROUP BY 
		p.ProductKey,
		EnglishDescription
),
average_sales AS (
	SELECT 
		AVG(TotalSales) AS AvgSales
	FROM product_sales
)
SELECT
	ProductName,
	TotalSales 
FROM product_sales, average_sales
WHERE TotalSales > AvgSales
ORDER BY TotalSales DESC;

-- Use a CTE to identify customers with declining sales over 3 consecutive months.
WITH monthly_customer_sales AS (
	-- Aggregate sales by customer and month
	SELECT 
        CustomerKey,
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS SalesMonth,
        SUM(SalesAmount) AS TotalSales
    FROM dbo.FactInternetSales
    GROUP BY CustomerKey, YEAR(OrderDate), MONTH(OrderDate)
),
sales_trends AS (
	-- Look back at the previous two months using LAG
	SELECT
		CustomerKey,
		SalesMonth,
		TotalSales,
		LAG(TotalSales, 1) OVER (PARTITION BY CustomerKey ORDER BY SalesMonth) AS PrevMonthSales,
		LAG(TotalSales, 2) OVER (PARTITION BY CustomerKey ORDER BY SalesMonth) AS TwoMonthsAgoSales
	FROM monthly_customer_sales
)
SELECT
	st.CustomerKey,
	CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
	SalesMonth AS DeclineDetectedMonth,
	TotalSales,
	PrevMonthSales,
	TwoMonthsAgoSales
FROM sales_trends st
INNER JOIN DimCustomer c
	ON st.CustomerKey = c.CustomerKey
WHERE TwoMonthsAgoSales > PrevMonthSales
AND PrevMonthSales > TotalSales
ORDER BY SalesMonth DESC, TotalSales DESC;

-- Calculate running total sales for each SalesTerritory using a CTE.
WITH territory_monthly_sales AS (
	SELECT
		SalesTerritoryCountry,
		DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS SalesMonth,
		SUM(SalesAmount) AS TotalSales
	FROM FactInternetSales s
	INNER JOIN DimSalesTerritory st
		ON s.SalesTerritoryKey = st.SalesTerritoryKey
	GROUP BY SalesTerritoryCountry, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
	SalesTerritoryCountry,
	SalesMonth,
	TotalSales,
	SUM(TotalSales) OVER (PARTITION BY SalesTerritoryCountry ORDER BY SalesMonth ASC) AS RunningTotal
FROM territory_monthly_sales;

-- Identify customers who have purchased all products from a specific ProductCategory using a CTE.
WITH customer_product_orders AS (
	SELECT 
		c.CustomerKey AS CustomerKey,
		pc.EnglishProductCategoryName AS ProductCategory,
		COUNT(DISTINCT p.EnglishProductName) AS ProductsOrdered
	FROM FactInternetSales s
	INNER JOIN DimCustomer c
		ON s.CustomerKey = c.CustomerKey
	INNER JOIN DimProduct p
		ON s.ProductKey = p.ProductKey
	INNER JOIN DimProductSubcategory psc
		ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
	INNER JOIN DimProductCategory pc
		ON psc.ProductCategoryKey = pc.ProductCategoryKey
	GROUP BY 
		c.CustomerKey,
		pc.EnglishProductCategoryName
),
products_per_product_category AS (
	SELECT 
		pc.EnglishProductCategoryName AS EnglishProductCategory,
		COUNT(DISTINCT EnglishProductName) AS ProductCategoryCount
	FROM FactInternetSales s
	INNER JOIN DimProduct p
		ON s.ProductKey = p.ProductKey
	INNER JOIN DimProductSubcategory psc
		ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
	INNER JOIN DimProductCategory pc
		ON psc.ProductCategoryKey = pc.ProductCategoryKey
	GROUP BY pc.EnglishProductCategoryName
)
SELECT
	cpo.CustomerKey,
	CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
	ProductCategory,
	ProductsOrdered
FROM customer_product_orders cpo
INNER JOIN DimCustomer c
	ON cpo.CustomerKey = c.CustomerKey
CROSS JOIN products_per_product_category 
WHERE ProductsOrdered = ProductCategoryCount;

-- Use a CTE to compute the sales variance between 2012 and 2014 per product.
WITH product_sales_2012 AS (
-- Get 2012 sales for each product
SELECT
	s.ProductKey,
	p.EnglishProductName,
	YEAR(OrderDate) AS Year,
	SUM(SalesAmount) AS TotalSales2012
FROM FactInternetSales s
INNER JOIN DimProduct p
	ON s.ProductKey = p.ProductKey
WHERE YEAR(OrderDate) = 2012
GROUP BY 
	s.ProductKey,
	p.EnglishProductName, 
	YEAR(OrderDate)
),
product_sales_2014 AS (
-- Get 2014 sales for each product
SELECT
	s.ProductKey,
	p.EnglishProductName,
	YEAR(OrderDate) AS Year,
	SUM(SalesAmount) AS TotalSales2014
FROM FactInternetSales s
INNER JOIN DimProduct p
	ON s.ProductKey = p.ProductKey
WHERE YEAR(OrderDate) = 2014
GROUP BY 
	s.ProductKey,
	p.EnglishProductName, 
	YEAR(OrderDate)
)
SELECT 
	s14.ProductKey AS ProductKey,
	s14.EnglishProductName AS ProductName,
	TotalSales2012,
	TotalSales2014,
	COALESCE(TotalSales2014 - TotalSales2012, TotalSales2014) AS SalesVariance
FROM product_sales_2014 s14
LEFT JOIN product_sales_2012 s12
	ON s14.ProductKey = s12.ProductKey
ORDER BY ProductKey;

-- Generate a CTE that finds products sold above the 75th percentile of UnitPrice.
WITH unit_price_percentile AS (
	SELECT --DISTINCT
		s.ProductKey AS ProductKey,
		EnglishProductName AS ProductName,
		UnitPrice,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY UnitPrice) OVER() AS Percentile_75_Cont
	FROM FactInternetSales s
	INNER JOIN DimProduct p
		ON s.ProductKey = p.ProductKey
)
SELECT DISTINCT
	ProductKey,
	ProductName,
	UnitPrice
FROM unit_price_percentile
WHERE UnitPrice > Percentile_75_Cont
ORDER BY ProductKey ASC

-- Find the top 5 customers in each territory using a window function inside a CTE.
WITH customer_territory_sales AS (
	SELECT 
		CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
		st.SalesTerritoryCountry AS Country,
		SUM(SalesAmount) AS TotalSales,
		DENSE_RANK() OVER (PARTITION BY st.SalesTerritoryCountry ORDER BY SUM(SalesAmount) DESC) AS CustomerRank
	FROM FactInternetSales s
	INNER JOIN DimCustomer c
		ON s.CustomerKey = c.CustomerKey
	INNER JOIN DimSalesTerritory st
		ON s.SalesTerritoryKey = st.SalesTerritoryKey
	GROUP BY
		CONCAT(c.FirstName, ' ', c.LastName),
		st.SalesTerritoryCountry
)
SELECT 
	FullName,
	Country,
	TotalSales,
	CustomerRank
FROM customer_territory_sales
WHERE CustomerRank <=5;

-- Using a CTE, calculate the average sales per month and flag months below the average.