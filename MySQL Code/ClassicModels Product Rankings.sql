USE classicmodels;

-- changes field name of status to orderStatus, because status is a reserved word in MySQL
ALTER TABLE orders
CHANGE status orderStatus VARCHAR(15);

-- list of products by quantity sold (ranking, product name, product code, quantity sold)
-- CTE is needed to use RANK() window function, because it cannot use quantity_sold field without a CTE
WITH product_quantity_sold AS(
	SELECT 
		p.productName,
		p.productCode,
		IFNULL(SUM(od.quantityOrdered), 0) AS quantity_sold,  -- returns 0 if value is null otherwise uses expression SUM(od.quantityOrdered)
        p.productLine
	FROM
		orderdetails od
			RIGHT JOIN	-- RIGHT JOIN needed to check for unsold products in this scenario the '1985 Toyota Supra' has no sales
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
	WHERE 
		o.orderStatus = "Shipped"
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
	GROUP BY productCode
)
SELECT
	RANK() OVER w AS ranking,
    productName,
    productCode,
    quantity_sold,
    productLine
FROM
	product_quantity_sold
WINDOW w AS (ORDER BY quantity_sold DESC);   

-- list of products by revenue (ranking, product name, product code, gross revenue)    
WITH products_by_revenue AS(
	SELECT
		p.productName,
		p.productCode,
		IFNULL(SUM(od.quantityOrdered * od.priceEach), 
				0) AS product_revenue,
        p.productLine
	FROM
		orderdetails od
			RIGHT JOIN
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
    WHERE 
		o.orderStatus = "Shipped" 
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL
	GROUP BY p.productCode
)
SELECT
	RANK() OVER w AS ranking,
    productName,
    productCode,
    product_revenue,
    productLine
FROM
	products_by_revenue
WINDOW w AS (ORDER BY product_revenue DESC);

-- list of products by profit (ranking, product name, product code, profit)
WITH cogs AS(  -- cost of goods sold
	SELECT  
		p.productCode,
		IFNULL(SUM(od.quantityOrdered * p.buyPrice), 0) AS cogs  -- returns 0 if value is null otherwise uses expression SUM(od.quantityOrdered)
	FROM
		orderdetails od
			RIGHT JOIN	-- RIGHT JOIN needed to check for unsold products in this scenario the '1985 Toyota Supra' has no sales
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
	WHERE 
		o.orderStatus = "Shipped"
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
	GROUP BY productCode
),
products_by_profit AS(
	SELECT
		p.productName,
		p.productCode,
		IFNULL(SUM(od.quantityOrdered * od.priceEach) - c.cogs, 
				0) AS product_profit,
        p.productLine
	FROM
		orderdetails od
			RIGHT JOIN
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
			JOIN
		cogs c ON c.productCode = p.productCode
    WHERE 
		o.orderStatus = "Shipped" 
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL
	GROUP BY p.productCode
)
SELECT
	RANK() OVER w AS ranking,
    productName,
    productCode,
    product_profit,
    productLine
FROM
	products_by_profit
WINDOW w AS (ORDER BY product_profit DESC);   

-- list of products by profit margin percentage (=profit/revenue)
WITH cogs AS(
	SELECT
		p.productCode,
		IFNULL(SUM(od.quantityOrdered * p.buyPrice), 0) AS cogs  -- returns 0 if value is null otherwise uses expression SUM(od.quantityOrdered)
	FROM
		orderdetails od
			RIGHT JOIN	-- RIGHT JOIN needed to check for unsold products in this scenario the '1985 Toyota Supra' has no sales
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
	WHERE 
		o.orderStatus = "Shipped"
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL  -- order status is null when product has 0 sales
	GROUP BY productCode
),
products_by_profit AS(
	SELECT
		p.productCode,
		IFNULL(SUM(od.quantityOrdered * od.priceEach) - cogs, 
				0) AS product_profit
	FROM
		orderdetails od
			RIGHT JOIN
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
			JOIN
		cogs c ON c.productCode = p.productCode
    WHERE 
		o.orderStatus = "Shipped" 
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL
	GROUP BY p.productCode
),
products_by_revenue AS(
	SELECT
		p.productName,
		p.productCode,
		IFNULL(SUM(od.quantityOrdered * od.priceEach), 
				0) AS product_revenue,
        p.productLine
	FROM
		orderdetails od
			RIGHT JOIN
		products p ON od.productCode = p.productCode
			LEFT JOIN
		orders o ON od.orderNumber = o.orderNumber
    WHERE 
		o.orderStatus = "Shipped" 
			OR o.orderStatus = "Resolved"
				OR o.orderStatus IS NULL
	GROUP BY p.productCode
),
products_by_margin AS(
	SELECT
		pr.productName,
		pr.productCode,
        IFNULL(ROUND(pp.product_profit / pr.product_revenue, 4), 
				0) AS product_margin,
        pr.productLine
	FROM 
		products_by_revenue pr
			JOIN
		products_by_profit pp ON pr.productCode = pp.productCode
)
SELECT
	RANK() OVER w AS ranking,
    productName,
    productCode,
    product_margin,
    productLine
FROM
	products_by_margin
WINDOW w AS (ORDER BY product_margin DESC);  