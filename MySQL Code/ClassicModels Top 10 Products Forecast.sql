USE classicmodels;

-- changes field name of status to orderStatus, because status is a reserved word in MySQL
ALTER TABLE orders
CHANGE status orderStatus VARCHAR(15);

-- Obtain all individual orders for the top 10 quantity sold products (Product Name, Order Date, Quantity)
WITH top_ten_products AS (  -- obtains top 10 products
	SELECT 
		od.productCode, 
		SUM(quantityOrdered) AS quantity_ordered
	FROM
		(SELECT 
			orderNumber
		FROM
			orders
		WHERE
			orderStatus = 'Resolved'
				OR orderStatus = 'Shipped') O
			JOIN
		orderdetails od ON o.orderNumber = od.orderNumber
	GROUP BY od.productCode
	ORDER BY quantity_ordered DESC
	LIMIT 10
)
SELECT
	p.productName,
    o.orderDate,
    od.quantityOrdered
FROM
	top_ten_products ttp
		JOIN
	orderdetails od ON ttp.productCode = od.productCode
		JOIN
	orders o ON od.orderNumber = o.orderNumber
		JOIN
	products p ON ttp.productCode = p.productCode
WHERE
	o.orderStatus = "Resolved"
		OR o.orderStatus = "Shipped";
