/*
===============================================================================
    Data Cleaning Script for Customer Analytics Project
===============================================================================

Description:
This script performs data cleaning and standardization on raw customer-related 
tables to prepare them for analysis. The process includes creating safe staging 
copies, deduplicating data, standardizing text fields, handling null and blank 
values, removing unnecessary columns, and establishing primary and foreign key 
constraints.

Steps:
1. Create staging tables to preserve raw data
2. Remove duplicate records using SELECT DISTINCT
3. Standardize string fields (e.g., TRIM, LOWER, unifying labels)
4. Handle null and blank values across key columns
5. Drop redundant columns and flag inaccurate data for later review
6. Set up appropriate primary and foreign keys across tables

Author      : Mitchell Rogers
Created     : Apr 2025
Database    : MySQL - MySQLWorkbench
Notes       : This is part of a data cleaning pipeline prior to analysis.
===============================================================================
*/

Select * from customers;

-- 1. Remove Duplicates
-- 2. Standardize the data
-- 3. Null values or blank values
-- 4. Remove any columns / rows
-- 5. Check and update PK / FK

-- 1. Finding and removing dupes

-- Create staging tables for each table, so as not to work on the real 'raw' data incase something goes wrong
-- Using DISTINCT to remove any duplicates

-- Staging tables are used for safety and repeatability.
-- In production pipelines, this process could be automated via a scheduled ETL job.

CREATE TABLE customers_staging
LIKE customers;

INSERT customers_staging
SELECT DISTINCT *
FROM customers;

SELECT *
FROM customers_staging;

CREATE TABLE campaigns_staging
LIKE campaigns;

INSERT campaigns_staging
SELECT DISTINCT *
FROM campaigns;

SELECT *
FROM campaigns_staging;

CREATE TABLE customer_segments_staging
LIKE customer_segments;

INSERT customer_segments_staging
SELECT DISTINCT *
FROM customer_segments;

SELECT *
FROM customer_segments_staging;

CREATE TABLE interactions_staging
LIKE interactions;

INSERT interactions_staging
SELECT DISTINCT *
FROM interactions;

SELECT *
FROM interactions_staging;

CREATE TABLE products_staging
LIKE products;

INSERT products_staging
SELECT DISTINCT *
FROM products;

SELECT *
FROM products_staging;

CREATE TABLE purchases_staging
LIKE purchases;

INSERT purchases_staging
SELECT DISTINCT *
FROM purchases;

SELECT *
FROM purchases_staging;

-- 2. Standardize the data

-- Removing white space from each tables text columns

-- TRIM removes extra whitespace; in some real-world cases, we might also need to remove invisible characters or handle non-breaking spaces (depending on source system)

SELECT first_name, TRIM(first_name),
last_name, TRIM(last_name),
email, TRIM(email),
gender, TRIM(gender),
country, TRIM(country),
city, TRIM(city)
FROM customers_staging;

UPDATE customers_staging
SET first_name = TRIM(first_name),
last_name = TRIM(last_name),
email = TRIM(email),
gender = TRIM(gender),
country = TRIM(country),
city = TRIM(city);


SELECT campaign_name, TRIM(campaign_name),
campaign_type, TRIM(campaign_type),
`channel`, TRIM(`channel`)
FROM campaigns_staging;

UPDATE campaigns_staging
SET campaign_name = TRIM(campaign_name),
campaign_type = TRIM(campaign_type),
`channel` = TRIM(`channel`);


SELECT segment_name, TRIM(segment_name),
criteria, TRIM(criteria)
FROM customer_segments_staging;

UPDATE customer_segments_staging
SET segment_name = TRIM(segment_name),
criteria = TRIM(criteria);


SELECT interaction_type, TRIM(interaction_type)
FROM interactions_staging;

UPDATE interactions_staging
SET interaction_type = TRIM(interaction_type);


SELECT product_name, TRIM(product_name),
category, TRIM(category)
FROM products_staging;

UPDATE products_staging
SET product_name = TRIM(product_name),
category = TRIM(category);

-- standardising data inputs

-- Finding variations of 'sms' (e.g., 'SMS', 'Sms campaigns') and standardizing to 'sms'
SELECT *
FROM campaigns_staging
WHERE campaign_type LIKE '%sms%';

-- Updating all 'sms' variations to lowercase 'sms'
UPDATE campaigns_staging
SET campaign_type = 'sms'
WHERE campaign_type LIKE '%sms%';

-- Finding variations of 'mail' campaign types (e.g., 'email campaign')
SELECT *
FROM campaigns_staging
WHERE campaign_type LIKE '%mail%';

-- Standardizing all 'mail' variations to 'email'
UPDATE campaigns_staging
SET campaign_type = 'email'
WHERE campaign_type LIKE '%mail%';

-- Final normalization: make all campaign types lowercase
UPDATE campaigns_staging
SET campaign_type = LOWER(campaign_type);

-- Finding channel values that reference Twitter or X
SELECT *
FROM campaigns_staging
WHERE `channel` LIKE '%x%' OR `channel` LIKE '%twitter%';

-- Unifying 'x', 'twitter', and similar values into 'twitter (x)'
UPDATE campaigns_staging
SET `channel` = 'twitter (x)'
WHERE `channel` LIKE '%x%' OR `channel` LIKE '%twitter%';

-- Finding LinkedIn channel variations like 'linkedin ads', 'linkedIn'
SELECT *
FROM campaigns_staging
WHERE `channel` LIKE 'linked%';

-- Standardizing all LinkedIn-related entries to 'linkedin'
UPDATE campaigns_staging
SET `channel` = 'linkedin'
WHERE `channel` LIKE 'linked%';

-- Making all channel values lowercase for consistency
UPDATE campaigns_staging
SET `channel` = LOWER(`channel`);

-- Finding interaction type entries related to clicks (e.g., 'clicked link', 'click-through')
SELECT *
FROM interactions_staging
WHERE interaction_type LIKE 'click%';

-- Standardizing all click-related interactions to 'Clicked'
UPDATE interactions_staging
SET interaction_type = 'Clicked'
WHERE interaction_type LIKE 'click%';

-- 3. Null / Blank values

-- Remove nulls currently shown in campaign_id columns within the purchases_staging table that are showing due to sales outside of campaigns

SELECT *
FROM purchases_staging;

SELECT *
FROM purchases_staging
WHERE campaign_id IS NULL;

UPDATE purchases_staging
SET campaign_id = 0
WHERE campaign_id IS NULL;

-- Insert new 'non-campaign' option into campaigns_staging table to cover all sales that are outside of campaigns - allows for more accurate tracking
INSERT INTO campaigns_staging (campaign_id, campaign_name, campaign_type, start_date, end_date, budget, `channel`)
VALUES (0, 'non_campaign', 'none', null, null, 0, 'none');

-- Update purchases_staging table to remove blanks from what should be int columns (currently text due to blanks)

-- =============================
-- Repeated product cleanup logic (refactorable)
-- =============================

-- The following block standardizes blank text values ('') in product fields to 0
-- This is repeated for each product column due to schema structure.
-- NOTE: In a production system, this could be refactored using a loop in a stored procedure
-- or dynamic SQL to make the process more scalable and maintainable.

-- Replacing blank strings in product_two fields with 0 (to allow for conversion to INT)
SELECT *
FROM purchases_staging
WHERE (product_two, product_two_num_cases) = ('','');

UPDATE purchases_staging
SET product_two = 0,
product_two_num_cases = 0
WHERE (product_two, product_two_num_cases) = ('','');

-- SELECT *
-- FROM purchases_staging
-- WHERE (product_three, product_three_num_cases) = ('','');

-- Same as above for product_three
UPDATE purchases_staging
SET product_three = 0,
product_three_num_cases = 0
WHERE (product_three, product_three_num_cases) = ('','');

-- SELECT *
-- FROM purchases_staging
-- WHERE (product_four, product_four_num_cases) = ('','');

-- Same as above for product_four
UPDATE purchases_staging
SET product_four = 0,
product_four_num_cases = 0
WHERE (product_four, product_four_num_cases) = ('','');

-- SELECT *
-- FROM purchases_staging
-- WHERE (product_five, product_five_num_cases) = ('','');

-- Same as above for product_five
UPDATE purchases_staging
SET product_five = 0,
product_five_num_cases = 0
WHERE (product_five, product_five_num_cases) = ('','');

-- Updating columns from text to int now that blanks have been updated to 0s

ALTER TABLE purchases_staging
MODIFY COLUMN product_two int;

ALTER TABLE purchases_staging
MODIFY COLUMN product_two_num_cases int;

ALTER TABLE purchases_staging
MODIFY COLUMN product_three int;

ALTER TABLE purchases_staging
MODIFY COLUMN product_three_num_cases int;

ALTER TABLE purchases_staging
MODIFY COLUMN product_four int;

ALTER TABLE purchases_staging
MODIFY COLUMN product_four_num_cases int;

ALTER TABLE purchases_staging
MODIFY COLUMN product_five int;

ALTER TABLE purchases_staging
MODIFY COLUMN product_five_num_cases int;

-- 4. Remove useless columns / rows

SELECT *
FROM interactions_staging;

-- Value column in the interactions_staging table is useless as it basically duplicates the interaction type into a number, removing it

ALTER TABLE interactions_staging
DROP COLUMN `value`;

SELECT *
FROM purchases_staging;

-- With further investigation, I have found that the purchases amount in the purchases_staging table is incorrect based on the other data available
-- This will be fixed during the data exploration stage later on so shall be left alone for now.


-- 5. Checking and Updating PKs / FKs

SELECT *
FROM purchases_staging;

-- As there are currently no PKs / FKs, I will go through each table below and add them in accordingly

-- 
ALTER TABLE campaigns_staging
ADD CONSTRAINT pk_campaigns_staging_id
PRIMARY KEY (campaign_id);

-- 
ALTER TABLE customer_segments_staging
ADD CONSTRAINT pk_customer_segments_staging_id
PRIMARY KEY (segment_id);

--
ALTER TABLE customers_staging
ADD CONSTRAINT pk_customers_staging_id
PRIMARY KEY (customer_id);

ALTER TABLE customers_staging -- Fixing column type differences
CHANGE `type` segment INT;

ALTER TABLE customers_staging
ADD CONSTRAINT fk_segment
FOREIGN KEY (segment)
REFERENCES customer_segments_staging(segment_id)
ON UPDATE CASCADE;

--
ALTER TABLE interactions_staging
ADD CONSTRAINT pk_interactions_staging_id
PRIMARY KEY (interaction_id);

ALTER TABLE interactions_staging
MODIFY customer_id BIGINT;

ALTER TABLE interactions_staging
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers_staging(customer_id)
ON UPDATE CASCADE;

ALTER TABLE interactions_staging
ADD CONSTRAINT fk_campaign
FOREIGN KEY (campaign_id)
REFERENCES campaigns_staging(campaign_id)
ON UPDATE CASCADE;

--
ALTER TABLE products_staging
ADD CONSTRAINT pk_products_staging_id
PRIMARY KEY (product_id);

--
ALTER TABLE purchases_staging
ADD CONSTRAINT pk_purchases_staging_id
PRIMARY KEY (purchase_id);

ALTER TABLE purchases_staging
MODIFY customer_id BIGINT;

ALTER TABLE purchases_staging
ADD CONSTRAINT fk_customer_purchase
FOREIGN KEY (customer_id)
REFERENCES customers_staging(customer_id)
ON UPDATE CASCADE;

ALTER TABLE purchases_staging
ADD CONSTRAINT fk_campaign_purchase
FOREIGN KEY (campaign_id)
REFERENCES campaigns_staging(campaign_id)
ON UPDATE CASCADE;
