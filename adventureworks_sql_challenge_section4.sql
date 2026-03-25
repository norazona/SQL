-- Section 4: Window Functions
-- Rank products by total sales within each Category using RANK() or DENSE_RANK().
SELECT 
	EnglishProductCategoryName AS Category,
	EnglishProductName AS ProductName,
	SUM(SalesAmount) AS TotalSales,
	RANK() OVER (PARTITION BY EnglishProductCategoryName ORDER BY SUM(SalesAmount) DESC) AS CategoryRank,
	DENSE_RANK() OVER (PARTITION BY EnglishProductCategoryName ORDER BY SUM(SalesAmount) DESC) AS CategoryDenseRank
FROM FactInternetSales s
INNER JOIN DimProduct p
	ON s.ProductKey = p.ProductKey
INNER JOIN DimProductSubcategory psc
	ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
INNER JOIN DimProductCategory pc
	ON psc.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY 
	EnglishProductName, 
	EnglishProductCategoryName;

-- Calculate the moving average of SalesAmount over the past 3 months.
SELECT 
	DATETRUNC(Month, OrderDate) AS OrderMonth,
	SUM(SalesAmount) AS AvgSalesAmount,
	AVG(SUM(SalesAmount)) OVER (ORDER BY DATETRUNC(Month, OrderDate) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MA
FROM FactInternetSales
GROUP BY DATETRUNC(Month, OrderDate);

-- Calculate the moving average of SalesAmount over the past 3 months for each territory.
WITH territory_monthly_sales AS (
-- Calculate the Monthly Average for each territory
	SELECT 
		SalesTerritoryRegion AS Territory,
		CalendarYear,
		MonthNumberOfYear,
		SUM(SalesAmount) AS MonthlySales
	FROM FactInternetSales s
	INNER JOIN DimDate d
		ON s.OrderDateKey = d.DateKey
	INNER JOIN DimSalesTerritory st
		ON s.SalesTerritoryKey = st.SalesTerritoryKey
	GROUP BY 
		SalesTerritoryRegion,
		CalendarYear,
		MonthNumberOfYear
)
SELECT
	Territory,
	CalendarYear,
	MonthNumberOfYear,
	MonthlySales,
	AVG(MonthlySales) OVER (
		PARTITION BY Territory 
		ORDER BY CalendarYear, MonthNumberOfYear ASC
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	) AS MovingAverage
FROM territory_monthly_sales
ORDER BY 
	Territory,
	CalendarYear,
	MonthNumberOfYear;

-- Compute the cumulative sum of OrderQuantity per Product.
SELECT 
	p.EnglishProductName AS Product,
	DATETRUNC(Month, OrderDate) AS OrderMonth,
	SUM(SalesAmount) AS MonthlySales,
	SUM(SUM(SalesAmount)) OVER (PARTITION BY p.EnglishProductName ORDER BY DATETRUNC(Month, OrderDate) ASC) AS CumulativeSum
FROM FactInternetSales s
INNER JOIN DimProduct p
	ON s.ProductKey = p.ProductKey
GROUP BY 
	p.EnglishProductName,
	DATETRUNC(Month, OrderDate)
ORDER BY 
	p.EnglishProductName,
	DATETRUNC(Month, OrderDate);	

-- Identify the previous month’s SalesAmount for each Customer using LAG().
WITH monthly_sales AS (
	-- Get the Monthly Sales by Customer
	SELECT
		CustomerKey,
		DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS SalesMonth,
		SUM(SalesAmount) AS MonthlySales
	FROM FactInternetSales 
	GROUP BY 
		CustomerKey,
		DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
)
SELECT 
	CustomerKey,
	SalesMonth,
	MonthlySales,
	COALESCE(LAG(MonthlySales) OVER (PARTITION BY CustomerKey ORDER BY SalesMonth ASC), 0) AS PreviousMonthSales
FROM monthly_sales;

-- Find customers whose monthly sales exceeded their average monthly sales using WINDOW() functions.
WITH customer_monthly_sales AS (
	-- Get the Monthly Sales by Customer
	SELECT
		CustomerKey,
		DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS SalesMonth,
		SUM(SalesAmount) AS MonthlySales
	FROM FactInternetSales 
	GROUP BY 
		CustomerKey,
		DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
),
customer_monthly_difference AS (
	SELECT 
		CustomerKey,
		SalesMonth,
		MonthlySales,
		AVG(MonthlySales) OVER (PARTITION BY CustomerKey) AS AvgMonthlySales,
		MonthlySales - AVG(MonthlySales) OVER (PARTITION BY CustomerKey) AS MonthlyDifference
	FROM customer_monthly_sales
)
SELECT
	CustomerKey,
	SalesMonth,
	MonthlySales,
	AvgMonthlySales,
	MonthlyDifference
FROM customer_monthly_difference
WHERE MonthlyDifference > 0;

-- Determine the top-selling product per month using ROW_NUMBER().
WITH product_monthly_sales AS (
	SELECT
		s.ProductKey,
		p.EnglishProductName AS ProductName,
		DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) AS YearMonth,
		SUM(SalesAmount) AS TotalSales
	FROM FactInternetSales s
	INNER JOIN DimProduct p
		ON s.ProductKey = p.ProductKey
	GROUP BY 
		s.ProductKey,
		p.EnglishProductName,
		DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
),
month_rank AS (
	SELECT 
		ProductKey,
		ProductName,
		YearMonth,
		TotalSales,
		ROW_NUMBER() OVER (PARTITION BY YearMonth ORDER BY TotalSales DESC) AS MonthlyRank
	FROM product_monthly_sales
)
SELECT 
	ProductKey,
	ProductName,
	YearMonth,
	TotalSales
FROM month_rank
WHERE MonthlyRank = 1
ORDER BY YearMonth ASC;

-- Calculate each product’s contribution to its Category’s total sales using SUM() OVER().

SELECT
	s.ProductKey,
	pc.EnglishProductCategoryName AS ProductCategory,
	p.EnglishProductName AS ProductName,
	SUM(SalesAmount) AS TotalSales,
	SUM(SUM(SalesAmount)) OVER (PARTITION BY pc.EnglishProductCategoryName) AS ProductCategorySales,
	(SUM(SalesAmount) / SUM(SUM(SalesAmount)) OVER (PARTITION BY pc.EnglishProductCategoryName)) * 100 AS ProductContributionPercent
FROM FactInternetSales s
INNER JOIN DimProduct p
	ON s.ProductKey = p.ProductKey
INNER JOIN DimProductSubcategory psc
	ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
INNER JOIN DimProductCategory pc
	ON psc.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY
	s.ProductKey,
	p.EnglishProductName,
	pc.EnglishProductCategoryName;

-- Rank customers by their SalesAmount growth rate over 6 months.

-- Identify the bottom 10% of products by sales in each Category using a window function.

-- Compute year-over-year growth in sales per Territory using window functions.