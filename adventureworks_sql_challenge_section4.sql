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

-- Identify the previous month’s SalesAmount for each Customer using LAG().

-- Find customers whose monthly sales exceeded their average monthly sales using WINDOW() functions.

-- Determine the top-selling product per month using ROW_NUMBER().

-- Calculate each product’s contribution to its Category’s total sales using SUM() OVER().

-- Rank customers by their SalesAmount growth rate over 6 months.

-- Identify the bottom 10% of products by sales in each Category using a window function.

-- Compute year-over-year growth in sales per Territory using window functions.