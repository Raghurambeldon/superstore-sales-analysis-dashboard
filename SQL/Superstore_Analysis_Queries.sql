CREATE TABLE staging_superstore_data (
    row_id int,
    order_id varchar(100),
    order_date varchar(50),  -- Changed to VARCHAR for safe import
    ship_date varchar(50),   -- Changed to VARCHAR for safe import
    ship_mode varchar(50),
    customer_id varchar(50),
    customer_name varchar(50),
    segment varchar(30),
    country varchar(30),
    city varchar(30),
    state varchar(30),
    postal_code bigint,
    region varchar(30),
    product_id varchar(50),
    category varchar(30),
    sub_category varchar(30),
    product_name varchar(200),
    sales float,
    quantity int,
    discount float,
    profit float,
    shipping_days int,
    order_year int,
    order_month varchar(20)
);




CREATE TABLE superstore_data (
    row_id int,
    order_id varchar(100),
    order_date date,         -- Proper DATE type
    ship_date date,          -- Proper DATE type
    ship_mode varchar(50),
    customer_id varchar(50),
    customer_name varchar(50),
    segment varchar(30),
    country varchar(30),
    city varchar(30),
    state varchar(30),
    postal_code bigint,
    region varchar(30),
    product_id varchar(50),
    category varchar(30),
    sub_category varchar(30),
    product_name varchar(200),
    sales float,
    quantity int,
    discount float,
    profit float,
    shipping_days int,
    order_year int,
    order_month varchar(20)
);


SET DateStyle TO 'ISO, DMY';


INSERT INTO superstore_data 
SELECT 
    row_id,
    order_id,
    TO_DATE(order_date, 'DD-MM-YYYY'), -- Reads incoming text as Day-Month-Year
    TO_DATE(ship_date, 'DD-MM-YYYY'),  -- Reads incoming text as Day-Month-Year
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    sales,
    quantity,
    discount,
    profit,
    shipping_days,
    order_year,
    order_month
FROM staging_superstore_data;


SELECT * FROM superstore_data LIMIT 10;

#1.SALES-OVER-YEARS(TIME) 

SELECT order_year,ROUND(SUM(sales)::NUMERIC,2) AS TOTAL_SALES
FROM superstore_data
GROUP BY order_year
ORDER BY order_year;

#2.ORDER-VOLUME-OVER-YEARS

SELECT order_year,COUNT(DISTINCT(order_id)) AS TOTAL_ORDERS
FROM superstore_data
GROUP BY order_year
ORDER BY order_year;


#3.PRODUCT-CATEGORIES GENERATING HIGHEST SALES AND PROFIT 

SELECT category,ROUND(SUM(sales)::NUMERIC,2) AS SALES,
ROUND(SUM(profit)::NUMERIC,2) AS PROFITS
FROM superstore_data
GROUP BY category
ORDER BY SALES DESC , PROFITS DESC;


#4.SUB-CATEGORIES MOST PURCHASED AND MORE PROFITABLE

SELECT sub_category,COUNT(DISTINCT(order_id)) AS ORDER_COUNT ,
ROUND(SUM(PROFIT)::NUMERIC,2) AS PROFITS
FROM superstore_data
GROUP BY sub_category
ORDER BY ORDER_COUNT DESC; 

#5.HIGHEST SALES AND PROFITS BY REGIONS

SELECT region, ROUND(SUM(sales)::NUMERIC,2) AS SALES,
ROUND(SUM(profit)::NUMERIC,2) AS PROFITS
FROM superstore_data
GROUP BY region
ORDER BY SALES DESC , PROFITS DESC; 


#6.HIGHEST ORDERS AND SALES BY CITIES 

SELECT city,COUNT(DISTINCT(order_id)) AS ORDERS ,
ROUND(SUM(sales)::NUMERIC,2) AS SALES
FROM superstore_data 
GROUP BY city
ORDER BY ORDERS DESC , SALES DESC
LIMIT 10;


#7.ORDERS BY SUB-CATEGORIES

SELECT sub_category,COUNT(DISTINCT(order_id)) AS ORDERS
FROM superstore_data 
GROUP BY sub_category
ORDER BY ORDERS DESC;


#8.CUSTOMERS ACROSS REGIONS

SELECT region,COUNT(DISTINCT(customer_id)) AS CUSTOMER_COUNT
FROM superstore_data
GROUP BY region
ORDER BY region;

#9.TOP 10 CUSTOMERS BY REVENUE AND PROFIT

SELECT customer_id,customer_name,
round(sum(sales)::numeric,2) as revenue,
round(sum(profit)::numeric,2) as profits
from superstore_data
group by customer_id,customer_name
order by revenue desc , profits desc 
LIMIT 10; 


#10.TOP 10 PRODUCTS BY REVENUE AND QUANTITY 

SELECT 
    product_id,
    product_name,
    ROUND(SUM(sales)::numeric, 2) AS revenue,
    SUM(quantity) AS quantity -- quantity is already an INT, no need to round or cast
FROM superstore_data
GROUP BY product_id, product_name
ORDER BY quantity DESC, revenue DESC 
LIMIT 10;

#11. DISCOUNTS IMPACT ON PROFITS,SALES AND QUANTITY

SELECT 
    discount,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(sales)::numeric, 2) AS avg_sales,
    ROUND(AVG(quantity)::numeric, 2) AS avg_quantity_per_order,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,
    ROUND(AVG(profit)::numeric, 2) AS avg_profit_per_order
FROM superstore_data
GROUP BY discount
ORDER BY discount ASC;

#12 AVERAGE SHIPPING DURATION ACROSS REGIONS AND CATEGORIES

SELECT region,category,round(avg(shipping_days)::numeric,2) as average_shipping_days
from superstore_data 
GROUP BY region,category
ORDER BY average_shipping_days desc;

#13.PRODUCTS PREFFERED BY DIFF CUSTOMER SEGMENTS

WITH ranked_products AS (
    SELECT 
        segment,
        product_id,
        product_name,
        COUNT(DISTINCT order_id) AS orders,
        DENSE_RANK() OVER (PARTITION BY segment ORDER BY COUNT(DISTINCT order_id) DESC) as product_rank
    FROM superstore_data
    GROUP BY segment, product_id, product_name
)
SELECT 
    segment,
    product_rank,
    product_name,
    orders
FROM ranked_products
WHERE product_rank <= 3 -- Keeps only the top 3 items for each segment
ORDER BY segment ASC, product_rank ASC;


#14.CITIES UNDERPERFORMING IN SALES AND PROFIT

SELECT 
    city,
    state, 
    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit
FROM superstore_data
GROUP BY city, state
ORDER BY total_profit ASC 
LIMIT 10;

#15.CUSTOMERS SEGMENT WHICH CONTRIBUTE MORE SALES AND PROFIT

SELECT 
    segment,
    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit
FROM superstore_data
GROUP BY segment
ORDER BY total_profit desc
LIMIT 10;



# -- Views -- 

-- #1. SALES OVER YEARS (TIME)
CREATE OR REPLACE VIEW v_sales_over_years AS
SELECT 
    order_year,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales
FROM superstore_data
GROUP BY order_year;


-- #2. ORDER VOLUME OVER YEARS
CREATE OR REPLACE VIEW v_order_volume_over_years AS
SELECT 
    order_year,
    COUNT(DISTINCT order_id) AS total_orders
FROM superstore_data
GROUP BY order_year;


-- #3. PRODUCT CATEGORIES GENERATING HIGHEST SALES AND PROFIT
CREATE OR REPLACE VIEW v_category_sales_profit AS
SELECT 
    category,
    ROUND(SUM(sales)::NUMERIC, 2) AS sales,
    ROUND(SUM(profit)::NUMERIC, 2) AS profits
FROM superstore_data
GROUP BY category;


-- #4. SUB-CATEGORIES MOST PURCHASED AND MORE PROFITABLE
CREATE OR REPLACE VIEW v_sub_category_sales_profit AS
SELECT 
    sub_category,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(profit)::NUMERIC, 2) AS profits
FROM superstore_data
GROUP BY sub_category;


-- #5. HIGHEST SALES AND PROFITS BY REGIONS
CREATE OR REPLACE VIEW v_regional_sales_profit AS
SELECT 
    region, 
    ROUND(SUM(sales)::NUMERIC, 2) AS sales,
    ROUND(SUM(profit)::NUMERIC, 2) AS profits
FROM superstore_data
GROUP BY region;


-- #6. HIGHEST ORDERS AND SALES BY CITIES
CREATE OR REPLACE VIEW v_city_orders_sales AS
SELECT 
    city,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(sales)::NUMERIC, 2) AS sales
FROM superstore_data 
GROUP BY city;


-- #7. ORDERS BY SUB-CATEGORIES
CREATE OR REPLACE VIEW v_orders_by_sub_category AS
SELECT 
    sub_category,
    COUNT(DISTINCT order_id) AS orders
FROM superstore_data 
GROUP BY sub_category;


-- #8. CUSTOMERS ACROSS REGIONS
CREATE OR REPLACE VIEW v_customers_across_regions AS
SELECT 
    region,
    COUNT(DISTINCT customer_id) AS customer_count
FROM superstore_data
GROUP BY region;


-- #9. TOP CUSTOMERS BY REVENUE AND PROFIT
CREATE OR REPLACE VIEW v_customer_revenue_profit AS
SELECT 
    customer_id,
    customer_name,
    ROUND(SUM(sales)::NUMERIC, 2) AS revenue,
    ROUND(SUM(profit)::NUMERIC, 2) AS profits
FROM superstore_data
GROUP BY customer_id, customer_name;


-- #10. TOP PRODUCTS BY REVENUE AND QUANTITY
CREATE OR REPLACE VIEW v_product_revenue_quantity AS
SELECT 
    product_id,
    product_name,
    ROUND(SUM(sales)::NUMERIC, 2) AS revenue,
    SUM(quantity) AS quantity
FROM superstore_data
GROUP BY product_id, product_name;


-- #11. DISCOUNTS IMPACT ON PROFITS, SALES AND QUANTITY
CREATE OR REPLACE VIEW v_discount_impact AS
SELECT 
    discount,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(sales)::NUMERIC, 2) AS avg_sales,
    ROUND(AVG(quantity)::NUMERIC, 2) AS avg_quantity_per_order,
    ROUND(SUM(profit)::NUMERIC, 2) AS total_profit,
    ROUND(AVG(profit)::NUMERIC, 2) AS avg_profit_per_order
FROM superstore_data
GROUP BY discount;


-- #12. AVERAGE SHIPPING DURATION ACROSS REGIONS AND CATEGORIES
CREATE OR REPLACE VIEW v_avg_shipping_duration AS
SELECT 
    region,
    category,
    ROUND(AVG(shipping_days)::NUMERIC, 2) AS average_shipping_days
FROM superstore_data 
GROUP BY region, category;


-- #13. PRODUCTS PREFERRED BY DIFF CUSTOMER SEGMENTS
CREATE OR REPLACE VIEW v_preferred_products_by_segment AS
WITH ranked_products AS (
    SELECT 
        segment,
        product_id,
        product_name,
        COUNT(DISTINCT order_id) AS orders,
        DENSE_RANK() OVER (PARTITION BY segment ORDER BY COUNT(DISTINCT order_id) DESC) AS product_rank
    FROM superstore_data
    GROUP BY segment, product_id, product_name
)
SELECT 
    segment,
    product_rank,
    product_name,
    orders
FROM ranked_products
WHERE product_rank <= 3; 


-- #14. CITIES UNDERPERFORMING IN SALES AND PROFIT
CREATE OR REPLACE VIEW v_underperforming_cities AS
SELECT 
    city,
    state, 
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(profit)::NUMERIC, 2) AS total_profit
FROM superstore_data
GROUP BY city, state;


-- #15. CUSTOMER SEGMENT WHICH CONTRIBUTE MORE SALES AND PROFIT
CREATE OR REPLACE VIEW v_segment_sales_profit AS
SELECT 
    segment,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(profit)::NUMERIC, 2) AS total_profit
FROM superstore_data
GROUP BY segment;

