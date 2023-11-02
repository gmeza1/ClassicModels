USE classicmodels;

-- changes field name of status to orderStatus, because status is a reserved word in MySQL
ALTER TABLE orders
CHANGE status orderStatus VARCHAR(15);

############################## annual product lines quantity sold (product line, quantity sold, year) #######################################################################
SELECT 
	p.productLine,
	IFNULL(SUM(od.quantityOrdered), 0) AS quantity_sold,  -- returns 0 if value is null otherwise uses expression SUM(od.quantityOrdered)
	oy.order_year
FROM
	orderdetails od
		RIGHT JOIN	-- RIGHT JOIN needed to check for unsold products in this scenario the '1985 Toyota Supra' has no sales
	products p ON od.productCode = p.productCode
		LEFT JOIN
	orders o ON od.orderNumber = o.orderNumber
		RIGHT JOIN
	(SELECT DISTINCT  -- obtains all the years orders where placed 2003-2005
		YEAR(orderDate) AS order_year
	FROM
		orders) oy ON YEAR(o.orderDate) = oy.order_year
WHERE 
	o.orderStatus = "Shipped"
		OR o.orderStatus = "Resolved"
			OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
GROUP BY oy.order_year, p.productLine
ORDER BY oy.order_year ASC, quantity_sold DESC;

######################## annual product lines revenue (product line, revenue, year) #########################################################
SELECT
	p.productLine,
	IFNULL(SUM(od.quantityOrdered * od.priceEach), 
			0) AS product_revenue,
	oy.order_year
FROM
	orderdetails od
		RIGHT JOIN
	products p ON od.productCode = p.productCode
		LEFT JOIN
	orders o ON od.orderNumber = o.orderNumber
		RIGHT JOIN
	(SELECT DISTINCT  -- obtains all the years orders where placed 2003-2005
		YEAR(orderDate) AS order_year
	FROM
		orders) oy ON YEAR(o.orderDate) = oy.order_year
WHERE 
	o.orderStatus = "Shipped" 
		OR o.orderStatus = "Resolved"
			OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
GROUP BY oy.order_year, p.productLine
ORDER BY oy.order_year ASC, product_revenue DESC;

############################# annual product lines profit (product line, profit, year) ##########################################################
WITH cogs AS (
	SELECT  
		p.productLine,
		IFNULL(SUM(od.quantityOrdered * p.buyPrice), 0) AS cogs,  -- returns 0 if value is null otherwise uses expression SUM(od.quantityOrdered)
		oy.order_year
	FROM
		orderdetails od
			RIGHT JOIN	-- RIGHT JOIN needed to check for unsold products in this scenario the '1985 Toyota Supra' has no sales
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
			RIGHT JOIN
		(SELECT DISTINCT  -- obtains all the years orders where placed 2003-2005
			YEAR(orderDate) AS order_year
		FROM
			orders) oy ON YEAR(o.orderDate) = oy.order_year
	WHERE 
		o.orderStatus = "Shipped"
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
	GROUP BY oy.order_year, p.productLIne
),
productline_revenue AS (
	SELECT
		p.productLine,
		IFNULL(SUM(od.quantityOrdered * od.priceEach), 
				0) AS productline_revenue,
		oy.order_year
	FROM
		orderdetails od
			RIGHT JOIN
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
			RIGHT JOIN
		(SELECT DISTINCT  -- obtains all the years orders where placed 2003-2005
			YEAR(orderDate) AS order_year
		FROM
			orders) oy ON YEAR(o.orderDate) = oy.order_year
	WHERE 
		o.orderStatus = "Shipped" 
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
	GROUP BY oy.order_year, p.productLine
)
SELECT
	c.productLine,
    pr.productline_revenue - c.cogs AS profit,
    c.order_year
FROM
	cogs c
		JOIN
	productline_revenue pr ON c.productLine = pr.productLine AND c.order_year = pr.order_year
ORDER BY c.order_year ASC, profit DESC;

########################################## annual product lines profit margin (product line, margin, year) #################################
WITH productline_profit AS(
	SELECT
		cogs.productLine,
		pr.productline_revenue - cogs.cogs AS profit,
		cogs.order_year
	FROM
		(SELECT  -- cost of goods sold
			p.productLine,
			IFNULL(SUM(od.quantityOrdered * p.buyPrice), 0) AS cogs,  -- returns 0 if value is null otherwise uses expression SUM(od.quantityOrdered)
			oy.order_year
		FROM
			orderdetails od
				RIGHT JOIN	-- RIGHT JOIN needed to check for unsold products in this scenario the '1985 Toyota Supra' has no sales
			products p ON od.productCode = p.productCode
				LEFT JOIN
			orders o ON od.orderNumber = o.orderNumber
				RIGHT JOIN
			(SELECT DISTINCT  -- obtains all the years orders where placed 2003-2005
				YEAR(orderDate) AS order_year
			FROM
				orders) oy ON YEAR(o.orderDate) = oy.order_year
		WHERE 
			o.orderStatus = "Shipped"
				OR o.orderStatus = "Resolved"
					OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
		GROUP BY oy.order_year, p.productLIne) cogs
			JOIN
		(SELECT  -- productline revenue
			p.productLine,
			IFNULL(SUM(od.quantityOrdered * od.priceEach), 
					0) AS productline_revenue,
			oy.order_year
		FROM
			orderdetails od
				RIGHT JOIN
			products p ON od.productCode = p.productCode
				LEFT JOIN
			orders o ON od.orderNumber = o.orderNumber
				RIGHT JOIN
			(SELECT DISTINCT  -- obtains all the years orders where placed 2003-2005
				YEAR(orderDate) AS order_year
			FROM
				orders) oy ON YEAR(o.orderDate) = oy.order_year
		WHERE 
			o.orderStatus = "Shipped" 
				OR o.orderStatus = "Resolved"
					OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
		GROUP BY oy.order_year, p.productLine) pr ON cogs.productLine = pr.productLine AND cogs.order_year = pr.order_year
),
productline_revenue AS (
	SELECT
		p.productLine,
		IFNULL(SUM(od.quantityOrdered * od.priceEach), 
				0) AS product_revenue,
		oy.order_year
	FROM
		orderdetails od
			RIGHT JOIN
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
			RIGHT JOIN
		(SELECT DISTINCT  -- obtains all the years orders where placed 2003-2005
			YEAR(orderDate) AS order_year
		FROM
			orders) oy ON YEAR(o.orderDate) = oy.order_year
	WHERE 
		o.orderStatus = "Shipped" 
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
	GROUP BY oy.order_year, p.productLine
)
SELECT
	pp.productLine,
    ROUND(pp.profit / pr.product_revenue, 4) AS product_line_margin,
    pp.order_year
FROM
	productline_profit pp
		JOIN
	productline_revenue pr ON pp.productLine = pr.productLine AND pp.order_year = pr.order_year
ORDER BY pp.order_year ASC, product_line_margin DESC;