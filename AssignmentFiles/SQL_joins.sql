USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
SELECT products.name AS product_name,
categories.name AS category_name,
products.price
FROM products 
INNER JOIN categories
ON products.category_id = categories.category_id;

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
SELECT order_items.order_id,
	order_items.quantity,
	orders.order_datetime,
	orders.store_id,
	stores.name AS store_name,
	products.name AS product_name,
	order_items.quantity * products.price AS line_total
FROM order_items
INNER JOIN orders ON order_items.order_id = orders.order_id
INNER JOIN stores ON stores.store_id = orders.store_id
INNER JOIN products ON order_items.product_id = products.product_id
ORDER BY
	order_datetime,
	order_id;

-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
SELECT 
	CONCAT(customers.first_name,' ', customers.last_name) AS customer_name,
	stores.name AS store_name,
    orders.order_datetime,
    SUM(order_items.quantity * products.price) AS order_total
FROM
	orders
INNER JOIN customers ON orders.customer_id = customers.customer_id
INNER JOIN stores ON orders.store_id = stores.store_id
INNER JOIN order_items ON orders.order_id = order_items.order_id
INNER JOIN products ON order_items.product_id = products.product_id
Where
	orders.status = 'paid'
GROUP BY
	orders.order_id, customer_name, store_name, orders.order_datetime
ORDER BY 
	orders.order_datetime;
    
-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
SELECT first_name,
	last_name,
    city,
    state
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id
WHERE orders.order_id IS NULL;


-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
WITH product_sales AS (
	SELECT 
		orders.store_id,
        stores.name AS store_name,
        products.name AS product_name,
		SUM(orders.quantity) AS total_units
	FROM orders
    JOIN stores ON orders.store_id = stores.store_id
    JOIN products ON orders.product_id = products.product_id
    WHERE orders.status = 'paid'
    GROUP BY orders.store_id, stores.name, products.name
),
ranked_products AS (
	SELECT 
		store_id,
        store_name,
        product_name,
        total_units,
		ROW_NUMBER() OVER (
			PARTITION BY store_id 
			ORDER BY total_units DESC
		) AS row_number
	FROM product_sales
)
SELECT store_name, product_name, total_units
FROM ranked_products
WHERE row_number = 1
ORDER BY store_name;

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
SELECT stores.name,
	products.name,
    inventory.on_hand
FROM inventory 
JOIN stores ON inventory.store_id = stores.store_id
JOIN products ON inventory.product_id = products.product_id
WHERE
	inventory.on_hand < 12;
    
-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
SELECT stores.name AS store_name,
	CONCAT(first_name, ' ' ,last_name) AS manager_name,
	hire_date
FROM stores
JOIN employees ON employees.store_id = stores.store_id
WHERE employees.title = 'Manager';

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
WITH product_revenue AS (
	SELECT products.name AS product_name,
		SUM(order_items.quantity * products.price) AS total_revenue
    FROM order_items
    JOIN orders ON order_items.order_id = orders.order_id
    JOIN products ON order_items.product_id = products.product_id
    WHERE orders.status = 'paid'
    GROUP BY products.name
)
SELECT product_name,
	total_revenue
FROM product_revenue
WHERE total_revenue > (
	SELECT AVG(total_revenue) FROM product_revenue
);
    
-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
SELECT CONCAT(customers.first_name, ' ', customers.last_name) AS customer_name, 
	customers.customer_id,
    MAX(orders.order_datetime) AS last_paid_order_date
FROM customers
LEFT JOIN orders ON customers.customer_id AND orders.status = 'paid'
GROUP BY customers.customer_id,
	customers.first_name,
    customers.last_name
ORDER BY last_paid_order_date;

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
WITH product_mix_report AS (
	SELECT 
    stores.store_id,
    products.category_id,
		SUM(order_items.quantity * products.price) AS total_revenue,
        SUM(order_items.quantity) AS total_units
    FROM order_items
    JOIN orders ON order_items.order_id = orders.order_id
    JOIN products ON order_items.product_id = products.product_id
    JOIN stores ON orders.store_id = stores.store_id
    WHERE orders.status = 'paid'
        GROUP BY stores.store_id, products.category_id      
)
SELECT total_revenue,
	total_units, 
    store_id,
    category_id
FROM product_mix_report


