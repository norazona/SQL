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

-- Calculate the moving average of SalesAmount over the past 3 months for each territory.

-- Compute the cumulative sum of OrderQuantity per Product.

-- Identify the previous month’s SalesAmount for each Customer using LAG().

-- Find customers whose monthly sales exceeded their average monthly sales using WINDOW() functions.

-- Determine the top-selling product per month using ROW_NUMBER().

-- Calculate each product’s contribution to its Category’s total sales using SUM() OVER().

-- Rank customers by their SalesAmount growth rate over 6 months.

-- Identify the bottom 10% of products by sales in each Category using a window function.

-- Compute year-over-year growth in sales per Territory using window functions.