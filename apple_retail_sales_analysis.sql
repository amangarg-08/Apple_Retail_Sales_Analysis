-- TO VIEW DATA

SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM sales;
SELECT * FROM stores;
SELECT * FROM warranty;


-- IMPROVING QUERY PERFORMANCE
EXPLAIN ANALYZE SELECT * FROM sales
WHERE product_id = 'P-30';
-- Execution time: 53ms 

CREATE INDEX sales_product_id on sales(product_id);

EXPLAIN ANALYZE SELECT * FROM sales
WHERE product_id = 'P-30';
-- After creation of indexes query performances are increased to
-- "Execution Time: 20 ms"

EXPLAIN ANALYZE SELECT * FROM sales
WHERE store_id = 'ST-11';
-- Execution time: 40ms 

CREATE INDEX sales_store_id on sales(store_id);

EXPLAIN ANALYZE SELECT * FROM sales
WHERE store_id = 'ST-11';
-- After creation of indexes query performances are increased to
-- "Execution Time: 13 ms"

SHOW INDEXES FROM sales;

-- BUSINESS PROBLEMS
-- 1. Find the number of stores in each country
SELECT 
	country, 
    COUNT(store_name) AS Total_Stores 
FROM stores 
GROUP BY country 
ORDER BY COUNT(store_name) DESC;


-- 2. Calculate the total number of units sold by each store.
SELECT 
	sales.store_id,
    stores.store_name,
    SUM(sales.quantity) AS Total_Units_Sold
FROM sales 
JOIN
stores
ON sales.store_id = stores.store_id
GROUP BY sales.store_id, stores.store_name
ORDER BY SUM(quantity) DESC;


-- 3.Find the total number of sales in December 2023.
SELECT 
	COUNT(*
    ) AS Total_Sales
FROM sales 
WHERE sale_date BETWEEN '2023-12-01' AND '2023-12-31';

-- 4.Determine how many stores have never had a warranty claim filed.
Select 
	COUNT(*) 
FROM stores 
WHERE store_id NOT IN (
SELECT store_id 
	FROM sales as s
RIGHT JOIN warranty as w 
ON s.sale_id = w.sale_id);


-- 5.Calcutate the percentage of warranty claims marked as "Rejected" .
SELECT 
    COUNT(*) AS total_records,
    SUM(repair_status = 'Rejected') AS rejected_count,
    ROUND((SUM(repair_status = 'Rejected') * 100.0 / COUNT(*)), 2) AS rejected_percentage
FROM warranty;


-- 6.Identify which store had the highest total units sold in the (2023-2024) year.
SELECT 
    stores.store_name, 
    SUM(sales.quantity) AS Total_Quantity
FROM sales 
JOIN stores on sales.store_id = stores.store_id
WHERE sales.sale_date BETWEEN '2023-04-01' AND '2024-03-31'
GROUP BY stores.store_name
ORDER BY SUM(sales.quantity) DESC
LIMIT 1;


-- 7. Count the number of unique products sold in the last year.
SELECT 
	COUNT(DISTINCT product_id) AS Unique_Products_Sold 
FROM sales 
WHERE sale_date BETWEEN '2023-04-01' AND '2024-03-31';


-- 8. Find the average price of products in each category.
SELECT 
	p.category_id, 
    c.category_name,
	ROUND(AVG(p.price), 2) AS avg_price
FROM products as p
JOIN category as c
ON p.category_id = c.category_id 
GROUP BY p.category_id, c.category_name
ORDER BY ROUND(AVG(p.price), 2) DESC;


-- 9. How many warranty claims were filed in 2024?
SELECT COUNT(*) FROM warranty WHERE claim_date BETWEEN '2024-01-01' AND '2024-12-31';


-- 10. For each store, identify the best-selling day based on highest quantity sold.
SELECT *
FROM (
		SELECT 
			store_id, 
			sale_date, 
            DATE_FORMAT(sale_date, '%W') as Day_name,
            SUM(quantity) as Total_quantity, 
            ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY SUM(quantity) DESC) as Ranks 
		FROM sales 
        GROUP BY store_id, sale_date) as TB1 
WHERE Ranks = 1 ;


-- 11. Identify the least selling product in each country based on total units sold.
SELECT * 
FROM
	(SELECT 
			st.country, 
			p.product_name,
			SUM(s.quantity) as total_quantity_sold,
			ROW_NUMBER() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) as Ranks
		FROM sales as s
		JOIN 
		stores as st
		on s.store_id = st.store_id
		JOIN
		products as p
		on s.product_id = p.product_id
		GROUP BY st.country, p.product_name) AS T1 
WHERE Ranks = 1;


-- 12. Calculate how many warranty claims were filed within 180 days of a product sale.
SELECT 
	COUNT(*)
FROM warranty as w
LEFT JOIN
sales as s
ON w.sale_id = s.sale_id
WHERE w.claim_date - s.sale_date > 0 AND w.claim_date - s.sale_date <= 180; 


-- 13. Determine how many warranty claims were filed for products launched in the last two years
SELECT 
	p.product_name,
    COUNT(w.claim_id) AS total_claims
FROM products as p 
JOIN
sales as s
ON p.product_id = s.product_id
JOIN 
warranty as w
ON w.sale_id = s.sale_id
WHERE launch_date >= CURDATE() - INTERVAL 2 YEAR
GROUP BY p.product_name;

-- 14. List the months in the last three years where sales exceeded 5000 units in the USA.
SELECT 
	st.country,
    DATE_FORMAT(s.sale_date, '%M-%Y') AS month_name,
    SUM(s.quantity) AS quantity_sold
FROM sales as s
JOIN 
stores as st
on s.store_id = st.store_id
WHERE st.country = 'United States' AND s.sale_date >= CURDATE() - INTERVAL 3 YEAR
GROUP BY DATE_FORMAT(s.sale_date, '%M-%Y'), st.country
HAVING SUM(s.quantity) > 5000
ORDER BY SUM(s.quantity);


-- 15. Identify the product category with the most warranty claims filed in the last two years.
SELECT 
	c.category_name, 
	COUNT(w.claim_date) AS total_claims
FROM warranty AS w
LEFT JOIN
sales AS s
ON  w.sale_id = s.sale_id
JOIN 
products AS p
ON p.product_id = s.product_id
JOIN 
category AS c
ON c.category_id = p.category_id
WHERE w.claim_date >= CURDATE() -  INTERVAL 2 YEAR
GROUP BY c.category_name
ORDER BY COUNT(w.claim_date) DESC; 


-- 16. Determine the percentage chance of receiving warranty claims after each purchase for each country.
 SELECT 
	st.country,
    SUM(s.quantity) AS total_quantity,
    COUNT(claim_id) AS total_claims,
    ROUND(((COUNT(claim_id) * 100) / SUM(s.quantity)), 2) AS risk_percentage
 FROM sales AS s
 JOIN stores AS st
 ON s.store_id = st.store_id
 LEFT JOIN warranty AS w
 ON s.sale_id = w.sale_id
 GROUP BY st.country;


-- 17. Analyze the year-by-year growth ratio for each store.
WITH yearly_sales AS
	(SELECT 
		st.store_name,
		DATE_FORMAT(s.sale_date, '%Y') AS yer,
		SUM(s.quantity * p .price) AS current_year_revenue
	FROM sales AS s
	JOIN stores AS st
	ON s.store_id = st.store_id
	JOIN products AS p
	ON s.product_id = p.product_id
	GROUP BY st.store_name, DATE_FORMAT(s.sale_date, '%Y')),
growth_ratio AS
		(SELECT 
			store_name,
			yer,
			current_year_revenue,
			LAG(current_year_revenue, 1) OVER(PARTITION BY store_name ORDER BY yer) AS previous_year_revenue
		FROM yearly_sales)

SELECT 
	store_name,
    yer,
    current_year_revenue,
    previous_year_revenue,
    ROUND(((current_year_revenue - previous_year_revenue) * 100/ previous_year_revenue), 2) AS growth_ratio
FROM 
growth_ratio;


-- 18. Calculate the correlation between product price and warranty claims for products sold in the tast five years, segmented by price range.
SELECT 
	CASE
    WHEN p.price < 500 THEN 'Lower Cost'
    WHEN p.price BETWEEN 500 AND 1000 THEN 'Moderate Cost'
    ELSE 'High Cost'
    END AS price_segmented,
    COUNT(w.claim_id) AS total_claims
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
LEFT JOIN warranty as w
ON s.sale_id = w.sale_id
GROUP BY 1;


-- 19. Identify the store with the highest percentage of "Completed" claims relative to total claims filed
WITH claims AS
(SELECT 
	st.store_id,
    st.store_name,
    COUNT(w.repair_status) AS total_claims_filed,
    SUM(CASE WHEN w.repair_status = 'Completed' THEN 1 ELSE 0 END) AS completed_claims
FROM sales AS s
JOIN stores AS st
ON s.store_id = st.store_id
RIGHT JOIN warranty as w
ON s.sale_id = w.sale_id
GROUP BY st.store_id, st.store_name)

SELECT 
	store_id,
    store_name,
    total_claims_filed,
    completed_claims,
    ROUND((completed_claims * 100 / total_claims_filed), 2) AS percentage
FROM claims
ORDER BY ROUND((completed_claims * 100 / total_claims_filed), 2) DESC;
    

-- 20. Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
WITH running_total 
AS
(SELECT 
	s.store_id,
    st.store_name,
    DATE_FORMAT(s.sale_date, '%m') AS month_number,
    DATE_FORMAT(s.sale_date, '%Y') AS year_,
    SUM(p.price * s.quantity) AS revenue
FROM sales AS s
JOIN stores AS st
ON s.store_id = st.store_id
JOIN products AS p
ON s.product_id = p.product_id
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 4, 3)

SELECT 
	store_id, 
    store_name,
    month_number,
    year_,
    revenue,
    SUM(revenue) OVER (PARTITION BY store_id ORDER BY year_, month_number) AS running_total
FROM
running_total;
