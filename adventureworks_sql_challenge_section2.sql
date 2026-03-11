-- Section 2: Joins & Relationships

-- List all customers along with their total sales, including customers with no sales.
SELECT 
	dc.CustomerKey,
	CONCAT(dc.FirstName, ' ',dc.LastName) AS FullName,
	COALESCE(SUM(fis.SalesAmount),0) AS TotalSales
FROM DimCustomer dc
LEFT JOIN FactInternetSales fis
	ON dc.CustomerKey = fis.CustomerKey
GROUP BY dc.CustomerKey, CONCAT(dc.FirstName, ' ',dc.LastName)
ORDER BY TotalSales DESC;

-- Retrieve SalesOrders with the corresponding SalesPerson and Territory.
SELECT
	s.SalesOrderNumber,
	t.SalesTerritoryRegion,
	CONCAT(e.FirstName, ' ',e.LastName) AS FullName
FROM FactResellerSales s
INNER JOIN DimEmployee e
	ON s.EmployeeKey = e.EmployeeKey
INNER JOIN DimSalesTerritory t
	ON s.SalesTerritoryKey = t.SalesTerritoryKey;

-- Identify products that have never been sold.
SELECT 
	p.ProductKey,
	p.EnglishProductName
FROM DimProduct p
LEFT JOIN FactInternetSales s
	ON p.ProductKey = s.ProductKey
LEFT JOIN FactResellerSales rs
	ON p.ProductKey = rs.ProductKey
WHERE s.ProductKey IS NULL
AND rs.ProductKey IS NULL;

-- Find the top 3 Products sold in each SalesTerritory.
WITH ranked_products AS (
	SELECT
		s.ProductKey,
		EnglishProductName,
		SalesTerritoryCountry,
		SUM(SalesAmount) AS TotalSales,
		DENSE_RANK() OVER(PARTITION BY SalesTerritoryCountry ORDER BY SUM(SalesAmount) DESC) AS ranked
	FROM FactInternetSales s
	INNER JOIN DimSalesTerritory t
		ON s.SalesTerritoryKey = t.SalesTerritoryKey
	INNER JOIN DimProduct p
		ON s.ProductKey = p.ProductKey
	GROUP BY 
		s.ProductKey, 
		EnglishProductName, 
		SalesTerritoryCountry
)
SELECT *
FROM ranked_products
WHERE ranked <= 3;

-- Show the total sales amount per Customer and the Region they belong to.
SELECT 
	c.CustomerKey,
	CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
	t.SalesTerritoryCountry,
	SUM(SalesAmount) AS TotalAmount
FROM FactInternetSales s
INNER JOIN DimCustomer c
	ON s.CustomerKey = c.CustomerKey
INNER JOIN DimSalesTerritory t
	ON s.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY 
	c.CustomerKey, 
	CONCAT(c.FirstName, ' ', c.LastName),
	t.SalesTerritoryCountry
ORDER BY TotalAmount DESC;

-- List Customers who purchased products from 2 or more categories.
SELECT 
	c.CustomerKey,
	CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
	COUNT(DISTINCT pc.ProductCategoryKey) AS ProductCategoryCount
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
	CONCAT(c.FirstName, ' ', c.LastName)
HAVING 
	COUNT(DISTINCT pc.ProductCategoryKey) >= 2
ORDER BY 
	ProductCategoryCount DESC,
	FullName ASC;

-- Retrieve all SalesOrders along with the associated ProductCategory and Subcategory.
SELECT
	s.SalesOrderNumber,
	pc.EnglishProductCategoryName,
	psc.EnglishProductSubcategoryName
FROM FactInternetSales s
INNER JOIN DimCustomer c
	ON s.CustomerKey = c.CustomerKey
INNER JOIN DimProduct p
	ON s.ProductKey = p.ProductKey
INNER JOIN DimProductSubcategory psc
	ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
INNER JOIN DimProductCategory pc
	ON psc.ProductCategoryKey = pc.ProductCategoryKey;

-- Show the CustomerName and SalesAmount for orders placed by salespeople in the “Central” territory.
SELECT 
	ResellerName AS CustomerName,
	st.SalesTerritoryRegion AS Territory,
	SalesAmount
FROM FactResellerSales rs
INNER JOIN DimReseller r
	ON rs.ResellerKey = r.ResellerKey
INNER JOIN DimSalesTerritory st
	ON rs.SalesTerritoryKey = st.SalesTerritoryKey
WHERE st.SalesTerritoryRegion = 'Central'
ORDER BY 
	CustomerName ASC,
	SalesAmount DESC

-- Join FactResellerSales with DimProduct to list products and their total reseller sales in 2013.
SELECT 
	p.EnglishProductName,
	ROUND(SUM(rs.SalesAmount),2) AS TotalSales
FROM FactResellerSales rs
INNER JOIN DimProduct p
	ON rs.ProductKey = p.ProductKey
WHERE YEAR(OrderDate) = 2013
GROUP BY p.EnglishProductName
ORDER BY TotalSales DESC;

-- Find all SalesOrders showing Customer name, SalesPerson name, Customer territory, and SalesPerson territory.
SELECT 
	s.SalesOrderNumber,
	CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
	CONCAT(e.FirstName, ' ', e.LastName) AS SalesPersonFullName,
	cst.SalesTerritoryRegion AS CustomerTerritory,
	est.SalesTerritoryRegion AS SalesPersonTerritory
FROM FactInternetSales s
-- Get Customer and their Territory via DimGeography
INNER JOIN DimCustomer c
	ON s.CustomerKey = c.CustomerKey
INNER JOIN DimGeography g
	ON c.GeographyKey = g.GeographyKey
INNER JOIN DimSalesTerritory cst
	ON g.SalesTerritoryKey = cst.SalesTerritoryKey
-- Get Salesperson and their Territory
INNER JOIN DimEmployee e
	ON s.SalesTerritoryKey = e.SalesTerritoryKey
INNER JOIN DimSalesTerritory est
	ON e.SalesTerritoryKey = est.SalesTerritoryKey;