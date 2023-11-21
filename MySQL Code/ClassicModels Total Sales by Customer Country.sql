/* Data extracted and saved to csv was later modified in Tableau to replace NULL values with $0 and 
records were added to improve the Tableau dashboard visualizations */
-- Obtain all orders with the customers country (Country, Product Name, Year of Order, Total Sales)
SELECT
	c.country,
	p.productName,
    o.orderDate,
    (od.quantityOrdered * od.priceEach) AS total_sales
FROM
	orders o
		JOIN
	orderdetails od ON o.orderNumber = od.orderNumber
		JOIN
	products p ON od.productCode = p.productCode
		JOIN
	customers c ON o.customerNumber = c.customerNumber
WHERE
	o.orderStatus = "Shipped"
		OR o.orderStatus = "Resolved"
ORDER BY country, productName, orderDate;



