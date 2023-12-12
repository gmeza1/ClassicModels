USE classicmodels;

-- changes field name of status to orderStatus, because status is a reserved word in MySQL
ALTER TABLE orders
CHANGE status orderStatus VARCHAR(15);

/* Create stored procedure to look up full order (order #, customer, order line number, order date, shipped date, required date, 
order status, product, quantity, price, product total, order total, comments) */
DROP PROCEDURE IF EXISTS search_order_number;

DELIMITER $$
CREATE PROCEDURE search_order_number(IN p_order_number INTEGER)
BEGIN
	SELECT
		o.orderNumber,
		c.customerName,
		od.orderLineNumber,
		o.orderDate,
		o.shippedDate,
        o.requiredDate,
		o.orderStatus,
		p.productName,
		od.quantityOrdered,
		od.priceEach,
		(od.quantityOrdered * od.priceEach) AS productTotal,
		ot.orderTotal,
		o.comments
	FROM
		orders o
			JOIN
		orderdetails od ON o.orderNumber = od.orderNumber
			JOIN
		products p ON od.productCode = p.productCode
			JOIN
		customers c ON o.customerNumber = c.customerNumber
			JOIN
		(SELECT	
			orderNumber,
			SUM(quantityOrdered * priceEach) AS orderTotal
		FROM
			orderdetails od
		WHERE
			orderNumber = p_order_number
		GROUP BY orderNumber) ot ON o.orderNumber = ot.orderNumber
	WHERE
		o.orderNumber = p_order_number
	ORDER BY od.orderLineNumber;
END$$

DELIMITER ;

CALL classicmodels.search_order_number('10127');

/*Stored procedure to search balance, credit limit, available credit, and other relevant information with the use of the customers phone # (numbers only eg:915559444)
(Customer, balance, credit limit, available credit, contact first name, contact last name, customer phone #, employee #, sales rep first name, sales rep last name, extension, email) */
DROP PROCEDURE IF EXISTS search_customer_balance_and_credit_by_phone_number;

DELIMITER $$
CREATE PROCEDURE search_customer_balance_and_credit_by_phone_number(IN p_customer_phone_number VARCHAR(20))
BEGIN
	WITH search_customer_by_phone AS(
		SELECT
			customerNumber,
			customerName,
			creditLimit,
			contactFirstName,
			contactLastName,
			phone AS customerPhone,
			salesRepEmployeeNumber
		FROM
			customers
		WHERE
			REGEXP_REPLACE(TRIM(phone), '[^0-9]', '') = p_customer_phone_number
	),
	customer_orders_total AS (
		SELECT
			sc.customerNumber,
			sc.customerName,
			SUM(od.priceEach * od.quantityOrdered) AS ordersTotal,
			sc.creditLimit,
			sc.contactFirstName,
			sc.contactLastName,
			sc.CustomerPhone,
			sc.salesRepEmployeeNumber
		FROM
			orders o 
				JOIN
			search_customer_by_phone sc ON o.customerNumber = sc.customerNumber
				JOIN
			orderdetails od ON o.orderNumber = od.orderNumber
		GROUP BY sc.customerNumber
	),
	customer_balance AS(
		SELECT
			ot.customerNumber,
			ot.customerName,
			-(ot.ordersTotal - SUM(p.amount)) AS balance,
			ot.creditLimit,
			(ot.creditLimit - (ot.ordersTotal - SUM(p.amount))) AS availableCredit,
			ot.contactFirstName,
			ot.contactLastName,
			ot.customerPhone,
			ot.salesRepEmployeeNumber
		FROM
			customer_orders_total ot
				JOIN
			payments p ON ot.customerNumber = p.customerNumber
		GROUP BY ot.customerNumber
	)
	SELECT 
		cb.*,
		e.firstName,
		e.lastName,
		e.extension,
		e.email
	FROM
		customer_balance cb
			JOIN
		employees e ON cb.salesRepEmployeeNumber = e.employeeNumber;
END $$

DELIMITER ;
    
CALL classicmodels.search_customer_balance_and_credit_by_phone_number('915559444');

