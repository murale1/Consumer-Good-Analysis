
-- 1.list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
SELECT DISTINCT(market)
FROM dim_customer
WHERE customer="Atliq Exclusive" and region="APAC";
-- 2.What is the percentage of unique product increase in 2021 vs. 2020


WITH unique_product as (SELECT
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_product_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_product_2021
FROM dim_product
JOIN fact_sales_monthly USING (product_code))

SELECT * , (unique_product_2021/unique_product_2020-1)*100 AS pct_change
FROM unique_product;

-- 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT segment, COUNT(DISTINCT (product_code)) AS No_of_unique_product
FROM dim_product
GROUP BY segment
ORDER BY No_of_unique_product DESC;

-- 4. Which segment had the most increase in unique products in 2021 vs 2020?

WITH unique_product AS (SELECT segment,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_product_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_product_2021
FROM dim_product
JOIN fact_sales_monthly USING (product_code)
GROUP BY segment)

SELECT * , unique_product_2021-unique_product_2020 AS Diff
FROM unique_product;

-- 5.Get the products that have the highest and lowest manufacturing costs.
SELECT product_code, product, manufacturing_cost
FROM fact_manufacturing_cost
JOIN dim_product
USING (product_code)
WHERE manufacturing_cost IN ((SELECT  MAX(manufacturing_cost) FROM fact_manufacturing_cost),
(SELECT  MIN(manufacturing_cost) FROM fact_manufacturing_cost));

-- 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market

SELECT customer_code ,customer, ROUND(pre_invoice_discount_pct*100,2) as Average_discount_perc FROM fact_pre_invoice_deductions
JOIN dim_customer 
USING (customer_code)
WHERE fiscal_year=2021 AND market="India"
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;

-- 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .

WITH CTE AS (select DATE_FORMAT(DATE,'%M') AS months ,YEAR(DATE) AS years, (sold_quantity * gross_price)  AS gross_sales_amount
FROM fact_gross_price
JOIN fact_sales_monthly
USING(product_code)
JOIN dim_customer
USING (customer_code)
WHERE customer="Atliq Exclusive")
SELECT months , years, ROUND(SUM(gross_sales_amount)/1000000,2) AS gros_sales_amount FROM CTE
GROUP BY months,years;

-- 8.In which quarter of 2020, got the maximum total_sold_quantity?
WITH Quarter_sales AS (Select *,CASE
       WHEN MONTH(DATE) IN (9,10,11) THEN "Q1"
       WHEN MONTH(DATE) IN (12,1,2) THEN "Q2"
       WHEN MONTH(DATE) IN (3,4,5) THEN "Q3"
       WHEN MONTH(DATE) IN (6,7,8) THEN "Q4"
       END AS Quarters
FROM fact_sales_monthly)
SELECT Quarters , ROUND(SUM(sold_quantity)/100000,2)AS total_sold_quantity
FROM Quarter_sales 
WHERE fiscal_year=2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC;


-- 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution

WITH channel_total_sales AS (SELECT CHANNEL, ROUND(SUM((sold_quantity*gross_price))/1000000,2) AS total_sales_amount
FROM fact_sales_monthly s
JOIN fact_gross_price g
USING (product_code,fiscal_year)
JOIN dim_customer c
USING (customer_code)
WHERE s.fiscal_year=2021
GROUP BY channel
)
SELECT *,ROUND(total_sales_amount*100/sum(total_sales_amount) OVER(),2) AS pct_share
FROM channel_total_sales
ORDER BY pct_share DESC;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021
WITH top3 AS (SELECT division, product_code,product, SUM(sold_quantity)  AS Total_quantity,DENSE_RANK() OVER(PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS top_3_product
FROM dim_product
JOIN fact_sales_monthly
USING (product_code)
WHERE fiscal_year='2021'
GROUP BY division, product_code,product)
SELECT * 
FROM top3
WHERE top_3_product <=3

