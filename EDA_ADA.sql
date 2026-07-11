------- EXPLORATORY DATA ANALYSIS (EDA) ---------

------ DATABASE EXPLORATION ------

--- Explore all objects in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES

--- Explore all columns in the database
SELECT *FROM INFORMATION_SCHEMA.COLUMNS

--- Explore Columns in a specific table
SELECT *FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='dim_customers'

------ DIMENSIONS EXPLORATION ------

--- Explore all countries our customers come from
SELECT DISTINCT country 
FROM gold.dim_customers

--- Explore all product categories
SELECT DISTINCT category,subcategory
FROM gold.dim_products

----- DATE EXPLORATION -----
--- Find the date of the first and last order and how many years of sales data is available

SELECT MIN(order_date) as FIRST_ORDER,
	   MAX(order_date) as FIRST_ORDER,
	   DATEDIFF(year,MIN(order_date),MAX(order_date)) as TOTAL_YEARS
from gold.fact_sales

--- Find the youngest and the oldest customer
SELECT MIN(birthdate) as oldest,
	   DATEDIFF(year,MIN(birthdate),GETDATE()) as oldest_age,
	   MAX(birthdate) as youngest,
	   DATEDIFF(year,MAX(birthdate),GETDATE()) as youngest_age
FROM gold.dim_customers;


----- MEASURE EXPLORATION -----

--- Find the total sales
SELECT SUM(sales_amount) as total_sales
FROM gold.fact_sales

--- Find how many items are sold 
SELECT SUM(CAST(quantity as int)) as total_quantity
FROM gold.fact_sales

--- Find the average selling price 
SELECT AVG(price) as avg_price
FROM gold.fact_sales

--- Find the total number of orders
SELECT COUNT(order_number) as total_orders
FROM gold.fact_sales

-- need to use distinct and multiple things can be ordered in 1 order
-- always compare after using distinct for accurate results
SELECT COUNT(DISTINCT order_number) as total_orders
FROM gold.fact_sales

--- Find the total number of products 
SELECT COUNT(product_id) as total_products
FROM gold.dim_products

--- Find the total number of customers 
SELECT COUNT(customer_key) as total_customers
FROM gold.dim_customers

--- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) as customers_with_order
FROM gold.fact_sales

--- Generate a report that shows all the key metrics of the business
SELECT 'Total Sales' as measure_name ,SUM(sales_amount) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' as measure_name ,SUM(CAST(quantity as int)) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Avg Selling Price' as measure_name ,AVG(price) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Number of Orders' as measure_name ,COUNT(DISTINCT order_number) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Number of products' as measure_name ,COUNT(product_id) as measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total Number of customers' as measure_name ,COUNT(customer_key) as measure_value FROM gold.dim_customers
UNION ALL
SELECT 'Customers that have placed an order' as measure_name ,COUNT(DISTINCT customer_key) as measure_value FROM gold.fact_sales


----- Magnitude Analysis -----

--- Find total customers by countries 
SELECT COUNT(customer_key) as total_customers_by_country,
		country
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers desc

--- Find total customers by gender
SELECT COUNT(customer_key) as total_customers_by_gender,
		gender
FROM gold.dim_customers
GROUP BY gender

--- Find total products by category 
SELECT COUNT(product_key) as total_products,
		category
FROM gold.dim_products
GROUP BY category
ORDER BY total_products desc

--- What is the avg costs in each category
SELECT AVG(CAST(cost as int)) as avg_cost,
		category
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost desc

--- What is the total revenue generated for each category --join fact(measure) first then dimension
SELECT SUM(f.sales_amount) as total_revenue,
	   d.category as category
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as d
on f.product_key=d.product_key
group by d.category
order by total_revenue desc

--- Find total revenue generate by each customer
SELECT SUM(f.sales_amount) as total_revenue,
	   d.customer_key as customer,
	   d.first_name as fName,
	   d.last_name as lName
FROM gold.fact_sales as f
LEFT JOIN gold.dim_customers as d
on f.customer_key=d.customer_key
group by d.customer_key,
	     d.first_name,
		 d.last_name
order by total_revenue desc

--- What is the distribution of sold items accross countries -- total quantity by countries
SELECT SUM(CAST(f.quantity as int)) as total_sold,
	   d.country
FROM gold.fact_sales as f
LEFT JOIN gold.dim_customers as d
ON f.customer_key = d.customer_key
group by d.country
order by total_sold


----- Ranking Analysis

--- Which 5 products generate the highest revenue
SELECT top 5 SUM(f.sales_amount) as revenue,
	   d.product_name
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as d
ON f.product_key = d.product_key
group by d.product_name
order by revenue desc

--- Window function
SELECT *
FROM
(
	SELECT SUM(f.sales_amount) as revenue,
		   d.product_name,
		   ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) desc) as rank_products
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_products as d
	ON f.product_key = d.product_key
	group by d.product_name
	)t
WHERE rank_products<=5


--- What are the 5 worst performing products in terms of sale
SELECT top 5 SUM(f.sales_amount) as revenue,
	   d.product_name
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as d
ON f.product_key = d.product_key
group by d.product_name
order by revenue


--- Find the top 10 customers who have generated the highest revenue
SELECT top 10 SUM(f.sales_amount) as revenue,
	   d.customer_key,
	   d.first_name,
	   d.last_name
FROM gold.fact_sales as f
LEFT JOIN gold.dim_customers as d
ON f.customer_key = d.customer_key
group by d.customer_key,
		 d.first_name,
		 d.last_name
order by revenue desc


--- three customers with the lowest orders places
SELECT top 10 COUNT(distinct order_number) as total_orders,
	   d.customer_key,
	   d.first_name,
	   d.last_name
FROM gold.fact_sales as f
LEFT JOIN gold.dim_customers as d
ON f.customer_key = d.customer_key
group by d.customer_key,
		 d.first_name,
		 d.last_name
order by total_orders




------- ADVANCED DATA ANALYTICS ---------

----- CHANGE OVER TIME -----

--- Analyse sales performance over time ---
--- can also count total no of customer
--- is the reveneue inc/dec? Are we gaining or losing customers?

SELECT YEAR(order_date) as order_year,
	   SUM(sales_amount) as total_sales,
	   COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--- drill down to months ---
-- understand seasonality of data. which months are best for sales.
SELECT MONTH(order_date) as order_month,
	   SUM(sales_amount) as total_sales,
	   COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

----- CUMULATIVE ANALYSIS -----

--- Calculate the total sales per month
--- and the running total of sales over time
--- and the moving avg price over time

SELECT order_month,
	   total_sales,
	   SUM(total_sales) OVER (ORDER BY order_month) as running_total_sales,
	   AVG(avg_price) OVER(ORDER BY order_month) as moving_avg_price
FROM
(
	SELECT MONTH(order_date) as order_month,
		   SUM(sales_amount) as total_sales,
		   AVG(price) as avg_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY MONTH(order_date)
)t


----- PERFORMANCE ANALYSIS -----

--- Analyse the yearly perfomance of products by comarparing each product's sales to both it's average sales perfomance and the 
--- previous year's sales

WITH yearly_product_sales as (
	SELECT 
		  YEAR(f.order_date) as order_year,
		  SUM(f.sales_amount) as current_sales,
		  p.product_name
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_products as p
	ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY YEAR(f.order_date),
			p.product_name
	)
SELECT order_year,
	   product_name,
	   current_sales,
	   AVG(current_sales) OVER(PARTITION BY product_name) as avg_sales,
	   current_sales - AVG(current_sales) OVER(PARTITION BY product_name) as diff_avg,
	   CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above avg'
			WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below avg'
			ELSE 'Avg'
	   END avg_change,
	   -- year over year analysis
	   LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) as py_sales,
	   current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) as py_diff,
	   CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
			WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
			ELSE 'No change'
	   END py_change
FROM yearly_product_sales
ORDER BY product_name,
		 order_year


----- PART TO WHOLE ANALYSIS -----

--- Which categories contribute the most to overall sales?

SELECT 
	  category,
	  total_sales,
	  SUM(total_sales) OVER() overall_sales,
	  CONCAT(ROUND((CAST(total_sales as FLOAT) / SUM(total_sales) OVER()) * 100,2),'%') as percentage_of_total
FROM (
	SELECT p.category as category,
		   SUM(f.sales_amount) as total_sales
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_products as p
	ON f.product_key = p.product_key
	GROUP BY p.category
)t
ORDER BY total_sales DESC


----- DATA SEGMENTATION -----

--- Segment products into cost ranges and count how many products fall into each segment 

WITH product_segments as (
	SELECT product_key,
		   product_name,
		   cost,
		   CASE WHEN cost < 100 THEN 'Below 100'
				WHEN cost BETWEEN 100 AND 500 THEN '100-500'
				WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
				ELSE 'Above 1000'
		   END cost_range
	FROM gold.dim_products
)
SELECT cost_range,
	   COUNT(product_key) as total_products
FROM product_segments
GROUP BY cost_range


--- GRoup customers into 3 segments based on their spending behaviour -
--- VIP : Customers with atleast 12 months of history and spending above 5000
--- Regular : Customers with atleast 12 months of history but spending 5000 or less
--- New : Customers with a lifespan less than 12 months
--- Also find the total no of customers by each group

WITH customer_spending AS (
	SELECT c.customer_key as customer_key,
		   SUM(f.sales_amount) as total_spending,
		   MIN(f.order_date) as first_order,
		   MAX(f.order_date) as last_order,
		   DATEDIFF(month,MIN(f.order_date),MAX(f.order_date)) as lifespan
	FROM gold.fact_sales as f
	LEFT JOIN gold.dim_customers as c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)
--- without subquery
SELECT COUNT(customer_key) as total_customers,
	CASE WHEN lifespan >=12 AND total_spending > 5000 THEN 'VIP'
		 WHEN lifespan >=12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
	END customer_segment
	FROM customer_spending
	GROUP BY CASE WHEN lifespan >=12 AND total_spending > 5000 THEN 'VIP'
		 WHEN lifespan >=12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
		 END
--with subquery
SELECT customer_segment,
	   COUNT(customer_key) as total_customers
FROM(
	SELECT customer_key,
	CASE WHEN lifespan >=12 AND total_spending > 5000 THEN 'VIP'
		 WHEN lifespan >=12 AND total_spending <= 5000 THEN 'Regular'
		 ELSE 'New'
	END customer_segment
	FROM customer_spending
	)t
GROUP BY customer_segment


