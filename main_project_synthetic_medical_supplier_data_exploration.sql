/*
================================================================================
    Exploratory Data Analysis Script for Customer Analytics Project
================================================================================

Description:
This script explores cleaned customer, product, campaign, and purchase data 
to uncover trends, identify high-performing segments, and evaluate campaign impact.

Author      : Mitchell Rogers
Created     : Apr 2025
Database    : MySQL - MySQLWorkbench
Notes       : Built on top of cleaned staging tables from previous script
================================================================================
*/

SELECT *
FROM customers_staging;

-- Understanding how many of the customers are based in the UK (roughly 80%)
SELECT *
FROM customers_staging
WHERE country = 'United Kingdom';

-- Looking at how many of the customers are stated to be frequent buyers using typology from the segment table (roughly 25%)
SELECT c.*, cs.segment_name
FROM customers_staging c
JOIN customer_segments_staging cs
ON c.`type` = cs.segment_id
WHERE `type` = 3;

-- Finding the best to worst performing campaigns based on all interactions (Best 3 - 10, 3, 1)(Worst 3 - 55, 60, 34)
SELECT campaign_id, COUNT(campaign_id)
FROM interactions_staging
GROUP BY campaign_id
ORDER BY COUNT(campaign_id) DESC;

-- Number of each interaction type for each campaign
-- Looks like there is an error with the data where each further type of interaction removes it from the previous count
-- ie. instead of the total number of interactions being shown on Viewed, only those that stopped at Viewed are counted
SELECT campaign_id, interaction_type, COUNT(interaction_type)
FROM interactions_staging
GROUP BY campaign_id, interaction_type
ORDER BY campaign_id ASC;

-- Dates -  Need to change from text to date
-- SELECT *
-- FROM purchases_staging
-- WHERE (date_field BETWEEN '2010-01-30 14:15:55' AND '2010-09-29 10:15:55');


-- Found another date column set as text - Can follow these steps to update the column safely, or just modify the column itself (as we are on staging)
SELECT *
FROM purchases_staging;

ALTER TABLE purchases_staging 
ADD COLUMN purchase_date_converted DATE;

UPDATE purchases_staging 
SET purchase_date = STR_TO_DATE(purchase_date, '%d/%m/%Y');

-- Take care using ALTER / DROP statements, another reason using a staging environment is always the best bet
ALTER TABLE purchases_staging 
DROP COLUMN purchase_date;

ALTER TABLE purchases_staging 
CHANGE COLUMN purchase_date_converted purchase_date DATE;

ALTER TABLE purchases_staging
MODIFY COLUMN purchase_date DATE;

-- The next 2 queries are a bit messy, but I was unsure on the best way to approach the odd data given by the table
-- A cleaner approach to use the data will be applied for visualisation to double check its accuracy.

-- With the updated date format, we can check how many cases of each item were sold each year
WITH yearly_product_cte AS (
	-- Step 1: Aggregate product one sales by year
	SELECT
		YEAR (purchase_date) AS `year`,
        product_one,
        SUM(product_one_num_cases) AS p_one_cases_sold
	FROM purchases_staging
	GROUP BY YEAR (purchase_date), product_one
    
	UNION ALL
    
    -- Step 2: Aggregate product two sales by year
	SELECT
		YEAR (purchase_date),
        product_two,
        SUM(product_two_num_cases) AS p_two_cases_sold
	FROM purchases_staging
	GROUP BY YEAR (purchase_date), product_two
    
	UNION ALL
    
    -- Step 3: Aggregate product three sales by year
	SELECT
		YEAR (purchase_date),
        product_three,
        SUM(product_three_num_cases) AS p_three_cases_sold
	FROM purchases_staging
	GROUP BY YEAR (purchase_date), product_three
    
	UNION ALL
    
    -- Step 4: Aggregate product four sales by year
	SELECT
		YEAR (purchase_date),
        product_four,
        SUM(product_four_num_cases) AS p_four_cases_sold
	FROM purchases_staging
	GROUP BY YEAR (purchase_date), product_four
    
	UNION ALL
    
    -- Step 5: Aggregate product five sales by year
	SELECT
		YEAR (purchase_date),
        product_five,
        SUM(product_five_num_cases) AS p_five_cases_sold
	FROM purchases_staging
	GROUP BY YEAR (purchase_date), product_five
    
    -- Ordering results by year and product for readability
	ORDER BY 1, 2 ASC
)
-- Step 6: Summarize total cases sold per product per year
SELECT
	`year`,
	product_one AS product,
    SUM(p_one_cases_sold) total_cases_sold
FROM yearly_product_cte
GROUP BY `year`, product_one
ORDER BY 1, 2 ASC;

-- Or we can dig deeper and group by the campaign ID instead, to understand how much of each product was sold during each campaign
WITH campaign_product_cte AS (
	-- Step 1: Aggregate product_one sales by campaign
	SELECT
		campaign_id,
        product_one,
        SUM(product_one_num_cases) AS p_one_cases_sold
	FROM purchases_staging
	GROUP BY campaign_id, product_one
    
	UNION ALL
    
    -- Step 2: Aggregate product_two sales by campaign
	SELECT
		campaign_id,
        product_two,
        SUM(product_two_num_cases) AS p_two_cases_sold
	FROM purchases_staging
	GROUP BY campaign_id, product_two
    
	UNION ALL
    
    -- Step 3: Aggregate product_three sales by campaign
	SELECT
		campaign_id,
        product_three,
        SUM(product_three_num_cases) AS p_three_cases_sold
	FROM purchases_staging
	GROUP BY campaign_id, product_three
    
	UNION ALL
    
    -- Step 4: Aggregate product_four sales by campaign
	SELECT
		campaign_id,
        product_four,
        SUM(product_four_num_cases) AS p_four_cases_sold
	FROM purchases_staging
	GROUP BY campaign_id, product_four
    
	UNION ALL
    
    -- Step 5: Aggregate product_five sales by campaign
	SELECT
		campaign_id,
        product_five,
        SUM(product_five_num_cases) AS p_five_cases_sold
	FROM purchases_staging
	GROUP BY campaign_id, product_five
    
    -- Ordering results by campaign and product for readability
	ORDER BY 1, 2 ASC
)

-- Final aggregation: sum total cases sold for each product per campaign
SELECT
	campaign_id,
    product_one AS product,
    SUM(p_one_cases_sold) total_cases_sold
FROM campaign_product_cte
GROUP BY campaign_id, product_one
ORDER BY 1, 2 ASC;

-- Creating a rolling total of sales across the months and years, along with a standard sum for each month alongside it

-- Quick inspection: uncomment to preview table
-- SELECT *
-- FROM purchases_staging;

SELECT SUBSTRING(purchase_date, 1, 7) `Month`,
ROUND(SUM(purchase_amount_pounds), 2)
FROM purchases_staging
WHERE SUBSTRING(purchase_date, 1, 7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

SELECT SUBSTRING(purchase_date, 1, 4) `Year`,
ROUND(SUM(purchase_amount_pounds), 2)
FROM purchases_staging
WHERE SUBSTRING(purchase_date, 1, 4) IS NOT NULL
GROUP BY `Year`
ORDER BY 1 ASC;

-- Step 1: Calculate monthly total purchase amounts
WITH Rolling_Monthly_Total AS (
	SELECT SUBSTRING(purchase_date, 1, 7) `Month`,
	ROUND(SUM(purchase_amount_pounds), 2) total_purchase_sum
	FROM purchases_staging
	WHERE SUBSTRING(purchase_date, 1, 7) IS NOT NULL
	GROUP BY `Month`
	ORDER BY 1 ASC
)
-- Step 2: Calculate rolling totals over months and rolling totals reset by year
SELECT `Month`,
total_purchase_sum,
ROUND(SUM(total_purchase_sum) OVER (
	ORDER BY `Month`
), 2) AS rolling_purchase_total,
ROUND(SUM(total_purchase_sum) OVER (
	PARTITION BY SUBSTRING(`Month`, 1, 4)
	ORDER BY `Month`
), 2) AS rolling_yearly_total
FROM Rolling_Monthly_Total;


-- Rank the top 5 customers for each year from 2020-2023
-- Using CTEs, Window Functions and other functions
SELECT customer_id, YEAR(purchase_date), ROUND(SUM(purchase_amount_pounds), 2)
FROM purchases_staging
GROUP BY customer_id, YEAR(purchase_date)
ORDER BY 3 DESC;

WITH Customer_Year (customer, years, total_purchase_amount) AS (
	SELECT customer_id, YEAR(purchase_date), ROUND(SUM(purchase_amount_pounds), 2)
	FROM purchases_staging
	GROUP BY customer_id, YEAR(purchase_date)
	ORDER BY 3 DESC
),
Customer_Year_Rank AS (
	SELECT *, DENSE_RANK() OVER (
		PARTITION BY years
		ORDER BY total_purchase_amount DESC
	) AS Ranking
	FROM Customer_Year
	WHERE years IS NOT NULL
	AND total_purchase_amount IS NOT NULL
)
SELECT *
FROM Customer_Year_Rank
WHERE Ranking <= 5;

-- Rank the top 5 customers based on each of the campaigns that have been run
SELECT p.customer_id, c.city, c.country,
cp.campaign_name, cp.`channel`,
ROUND(SUM(purchase_amount_pounds), 2)
FROM purchases_staging p
LEFT JOIN customers_staging c
ON p.customer_id = c.customer_id
LEFT JOIN campaigns_staging cp
ON p.campaign_id = cp.campaign_id
GROUP BY p.customer_id, c.city, c.country, cp.campaign_name, cp.`channel`
ORDER BY 6 DESC;

WITH Customer_Campaign (customer, city, country, campaign, `channel`, total_purchase_amount) AS (
	SELECT p.customer_id, c.city, c.country,
	cp.campaign_name, cp.`channel`,
	ROUND(SUM(purchase_amount_pounds), 2)
	FROM purchases_staging p
	LEFT JOIN customers_staging c
	ON p.customer_id = c.customer_id
	LEFT JOIN campaigns_staging cp
	ON p.campaign_id = cp.campaign_id
	GROUP BY p.customer_id, c.city, c.country, cp.campaign_name, cp.`channel`
	ORDER BY 6 DESC
),
Customer_Campaign_Rank AS (
	SELECT *, DENSE_RANK() OVER (
		PARTITION BY campaign
		ORDER BY total_purchase_amount DESC
	) AS Ranking
	FROM Customer_Campaign
	WHERE campaign IS NOT NULL
	AND total_purchase_amount IS NOT NULL
)
SELECT *
FROM Customer_Campaign_Rank
WHERE Ranking <= 5;

-- Quick inspection: uncomment to preview table
-- SELECT *
-- FROM purchases_staging;

-- Joins multiple tables together to create an overview of how each campaign has performed,
-- comparing interactions vs sales as well as profit from each.
WITH purchases_performance AS (
	SELECT ROW_NUMBER() OVER (
		ORDER BY campaign_id
	) performance_id,
	campaign_id,
	COUNT(*) total_sales,
    ROUND(SUM(purchase_amount_pounds), 2) total_revenue
	FROM purchases_staging
	GROUP BY campaign_id
),
interactions_performance AS (
	SELECT campaign_id,
	COUNT(interaction_id) total_interactions
	FROM interactions_staging
	GROUP BY campaign_id
),
campaigns_performance AS (
	SELECT campaign_id, budget
	FROM campaigns_staging
)
SELECT p.performance_id,
p.campaign_id,
ROUND(i.total_interactions * (RAND()*(11-6)+6), 0) total_interactions, -- !!!Synthetic workaround!!!: Due to the lack of real interaction data, RAND() is used to simulate conversion behaviour.
p.total_sales,														   -- This would never be used in a real-world scenario. For demonstration only.
ROUND(p.total_sales / (i.total_interactions * (RAND()*(11-6)+6)) * 100, 2) `conversion_%`,
c.budget,
p.total_revenue,
ROUND(p.total_revenue - c.budget, 2) profit
FROM purchases_performance p
LEFT JOIN interactions_performance i
ON p.campaign_id = i.campaign_id
JOIN campaigns_performance c
ON p.campaign_id = c.campaign_id
GROUP BY p.campaign_id, i.total_interactions, c.budget
ORDER BY performance_id;


/*
================================================================================
    Summary & Next Steps
================================================================================

This exploratory analysis identified key customer segments, top-performing 
campaigns, product trends over time, and campaign effectiveness metrics 
including sales, revenue, and estimated conversion rates.

Key insights:
- UK customers dominate the customer base (~80%)
- Campaigns show varying success levels; some drive significantly more sales
- Product sales vary by year and campaign, with seasonal and performance patterns
- Rolling sales metrics provide clear trends for visualization

Next Steps:
- Integrate data into Excel and Power BI for enhancements and interactive dashboards
- If done again, replace synthetic elements (e.g., use of RAND()) with real interaction data where possible
- Consider building final reporting views or stored procedures for reuse

*/


