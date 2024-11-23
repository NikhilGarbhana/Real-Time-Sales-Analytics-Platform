SELECT ProductName, SUM(Quantity) AS TotalSold
FROM SalesFact
JOIN Products ON SalesFact.ProductID = Products.ProductID
GROUP BY ProductName
ORDER BY TotalSold DESC;