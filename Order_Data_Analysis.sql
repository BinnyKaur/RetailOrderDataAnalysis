use mydemo;
select * from df_orders;
-- find 10 highest revenue generating products 
SELECT product_id, sum(sale_price) as sales
FROM df_orders
GROUP BY product_id
ORDER BY sales desc
LIMIT  10;

-- Using CTE to give Row Number 
WITH ranked_products AS 
(
	SELECT product_id, 
		SUM(sale_price) AS sales, 
        ROW_NUMBER() OVER (ORDER BY SUM(sale_price) DESC ) AS index_number
	FROM df_orders
    GROUP BY product_id 
)
SELECT 
	index_number, 
    product_id, 
    sales
FROM ranked_products
ORDER BY index_number 
LIMIT 10;

-- find top 5 highest selling products in each region
WITH CTE AS(
	SELECT region, 
		product_id, 
        sum(sale_price) AS sales
	FROM df_orders
    GROUP BY region, product_id)
SELECT * FROM (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales desc) as rn 
	FROM CTE ) A 
WHERE rn<=5;

-- find month over month growth comparison for 2022 and 2023 sales eg: Jan 2022 vs Jan 2023
WITH CTE AS (
SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month, 
SUM(sale_price) AS sales
FROM df_orders
GROUP BY year(order_date), month(order_date)
)
SELECT 
	order_month, 
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022, 
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM CTE 
GROUP BY order_month
ORDER BY order_month;

-- for each category which month had highest sales 
WITH CTE AS (
SELECT 
    category, 
    DATE_FORMAT(order_date,'%Y%m') AS order_year_month,
    SUM(sale_price) AS sales 
FROM df_orders
GROUP BY category, order_year_month

)
SELECT * FROM (
SELECT * , 
ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales desc) as rn
FROM CTE) A 
WHERE rn =1;

-- which sub category had highest growth by profit in 2023 compare to 2022
WITH CTE AS (
SELECT 
    sub_category, 
    year(order_date) AS order_year,
    SUM(sale_price) AS sales 
FROM df_orders
GROUP BY sub_category, order_year
), 
CTE2 AS(
SELECT 
	sub_category, 
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022, 
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM CTE 
GROUP BY sub_category 
)
SELECT * 
, (sales_2023 - sales_2022)*100/ sales_2022 AS growth_percent
FROM cte2
ORDER BY growth_percent desc
LIMIT 1;
