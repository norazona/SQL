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



-- Identify products that have never been sold.



-- Find the top 3 Products sold in each SalesTerritory.



-- Show the total sales amount per Customer and the Region they belong to.



-- List Customers who purchased products from more than 3 categories.



-- Retrieve all SalesOrders along with the associated ProductCategory and Subcategory.



-- Show the CustomerName and SalesAmount for orders placed by salespeople in the “Central” territory.



-- Join FactResellerSales with DimProduct to list products and their total reseller sales in 2023.



-- Find all SalesOrders where the Customer and SalesPerson are from different Territories.
