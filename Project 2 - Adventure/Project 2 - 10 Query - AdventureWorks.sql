-- 1. Doanh thu từng năm kèm tăng trưởng % so với năm trước
WITH yearly_revenue AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        SUM(TotalDue) AS TotalRevenue
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
)
SELECT 
    Year,
    TotalRevenue,
    LAG(TotalRevenue) OVER (ORDER BY Year) AS PrevYearRevenue,
    ROUND(
        100.0 * (TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY Year)) / 
        LAG(TotalRevenue) OVER (ORDER BY Year), 2
    ) AS GrowthPercent
FROM yearly_revenue
ORDER BY Year;

-- 2. Top 5 sản phẩm doanh thu cao nhất trong từng năm
WITH yearly_product_sales AS (
    SELECT 
        YEAR(h.OrderDate) AS Year,
        p.Name AS ProductName,
        SUM(d.LineTotal) AS Revenue
    FROM Sales.SalesOrderDetail d
    JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
    JOIN Production.Product p ON d.ProductID = p.ProductID
    GROUP BY YEAR(h.OrderDate), p.Name
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Revenue DESC) AS rn
    FROM yearly_product_sales
) ranked
WHERE rn <= 5
ORDER BY Year, Revenue DESC;

-- 3. Xếp hạng khách hàng theo tổng chi tiêu và phân loại nhóm
WITH customer_spending AS (
    SELECT 
        c.CustomerID,
        p.FirstName + ' ' + p.LastName AS CustomerName,
        SUM(h.TotalDue) AS TotalSpent
    FROM Sales.SalesOrderHeader h
    JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
    JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    GROUP BY c.CustomerID, p.FirstName, p.LastName
)
SELECT 
    CustomerName,
    TotalSpent,
    RANK() OVER (ORDER BY TotalSpent DESC) AS RankCustomer,
    CASE 
        WHEN TotalSpent >= 50000 THEN 'VIP'
        WHEN TotalSpent BETWEEN 10000 AND 49999 THEN 'Regular'
        ELSE 'Occasional'
    END AS CustomerSegment
FROM customer_spending
ORDER BY TotalSpent DESC;


-- 4. Doanh thu trung bình lăn (rolling average) 3 tháng
WITH monthly_sales AS (
    SELECT 
        FORMAT(OrderDate, 'yyyy-MM') AS YearMonth,
        SUM(TotalDue) AS MonthlyRevenue
    FROM Sales.SalesOrderHeader
    GROUP BY FORMAT(OrderDate, 'yyyy-MM')
)
SELECT 
    YearMonth,
    MonthlyRevenue,
    ROUND(
        AVG(MonthlyRevenue) OVER (ORDER BY YearMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
        2
    ) AS Rolling3MonthAvg
FROM monthly_sales
ORDER BY YearMonth;

-- 5. Xếp hạng hiệu suất nhân viên bán hàng theo từng năm
WITH sales_by_person AS (
    SELECT 
        sp.BusinessEntityID AS EmployeeID,
        YEAR(h.OrderDate) AS Year,
        SUM(h.TotalDue) AS TotalRevenue
    FROM Sales.SalesOrderHeader h
    JOIN Sales.SalesPerson sp ON h.SalesPersonID = sp.BusinessEntityID
    GROUP BY sp.BusinessEntityID, YEAR(h.OrderDate)
)
SELECT 
    Year,
    EmployeeID,
    TotalRevenue,
    RANK() OVER (PARTITION BY Year ORDER BY TotalRevenue DESC) AS RankInYear
FROM sales_by_person
ORDER BY Year, RankInYear;

-- 6. Sản phẩm có doanh thu vượt trung bình toàn bộ
WITH product_sales AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        SUM(d.LineTotal) AS Revenue
    FROM Sales.SalesOrderDetail d
    JOIN Production.Product p ON d.ProductID = p.ProductID
    GROUP BY p.ProductID, p.Name
)
SELECT 
    ProductName,
    Revenue,
    AVG(Revenue) OVER () AS AvgRevenueAll,
    CASE WHEN Revenue > AVG(Revenue) OVER () THEN 'Above Average'
         ELSE 'Below Average' END AS Performance
FROM product_sales
ORDER BY Revenue DESC;

-- 7. Tỷ lệ khách hàng quay lại (Repeat Customers)
WITH customer_orders AS (
    SELECT 
        c.CustomerID,
        COUNT(DISTINCT h.SalesOrderID) AS NumOrders
    FROM Sales.SalesOrderHeader h
    JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
    GROUP BY c.CustomerID
)
SELECT 
    COUNT(CASE WHEN NumOrders > 1 THEN 1 END) * 100.0 / COUNT(*) AS RepeatCustomerPercent
FROM customer_orders;

--8. Doanh thu theo loại sản phẩm
SELECT 
    pc.Name AS Category,
    SUM(d.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail d
JOIN Production.Product p ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY TotalRevenue DESC;

--9. Doanh thu theo tháng (trend mùa vụ)
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

--10. Doanh thu theo vùng kinh doanh (Sales Territory)

SELECT 
    t.Name AS Territory,
    SUM(h.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
GROUP BY t.Name
ORDER BY TotalRevenue DESC;
