-- ### App Trader

-- Your team has been hired by a new company called App Trader to help them explore and gain insights from apps that are made available through the Apple App Store and Android Play Store. App Trader is a broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchase. 

-- Unfortunately, the data for Apple App Store apps and Android Play Store Apps is located in separate tables with no referential integrity.

-- f. Verify that you have two tables:  
--     - `app_store_apps` with 7197 rows  
--     - `play_store_apps` with 10840 rows

SELECT *
FROM app_store_apps;
--returns 7197 rows

SELECT *
FROM play_store_apps;
--returns 10840 rows

-- #### 2. Assumptions

-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
-- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- - An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- updated 2/18/2023

--Testing JOINS
SELECT *
FROM app_store_apps
WHERE name IN (SELECT name FROM play_store_apps);

SELECT a.name, p.name, a.rating, p.rating, a.price, p.price
FROM app_store_apps AS a, play_store_apps AS p
WHERE a.name=p.name AND CAST(a.price AS MONEY)=CAST(p.price AS MONEY);

-- SELECT *
-- FROM left_table
-- UNION ALL
-- SELECT *
-- FROM right_table;

SELECT 'app_store' AS store_name,name, rating, CAST(price AS MONEY)
FROM app_store_apps AS a
UNION ALL
SELECT 'play_store' AS store_name,name, rating, CAST(price AS MONEY)
FROM play_store_apps AS p
ORDER BY name;
--combines both tables, adds for store, 


--Kieran--Test
SELECT name, 'play_store' AS store_name, CAST(rating AS NUMERIC), CAST(price AS MONEY), genres AS genre 
FROM play_store_apps AS p
WHERE rating IS NOT NULL
	AND rating > 4.9
UNION ALL
SELECT name, 'app_store' AS store_name, CAST(rating AS NUMERIC), CAST(price AS MONEY), primary_genre AS genre
FROM app_store_apps AS a
WHERE rating IS NOT NULL
	AND rating > 4.9
GROUP BY name, rating, price, genre
ORDER BY rating, price;

---AS CTE RUNS....
WITH app AS (
SELECT DISTINCT (name), 'app_store' AS store_name, rating, CAST(price AS MONEY)
FROM app_store_apps AS a),
play AS (
SELECT DISTINCT (name), 'play_store' AS store_name, rating, CAST(price AS MONEY)
FROM play_store_apps AS p)
SELECT app.store_name, play.store_name, app.name,play.name, app.rating, play.rating, app.price, play.price
FROM app
JOIN play
ON app.name=play.name AND app.price=play.price
ORDER BY app.name;
---AS CTE RUNS.... 

--Attempting to Build Full Table
SELECT 'app_store' AS store_name,name, CAST(price AS MONEY), rating AS cust_rating, content_rating, primary_genre AS genre
FROM app_store_apps AS a
UNION ALL
SELECT 'play_store' AS store_name,name, CAST(price AS MONEY), rating AS cust_rating, content_rating, genres AS genre
FROM play_store_apps AS p
ORDER BY name;
--returns all rows....18037
--use above table as subquery in FROM for additional queries????

--Add Purchase Price Column...seth
SELECT DISTINCT(name), CAST(price AS MONEY),
	CASE
		WHEN price > 0 THEN (price * 10000)
		WHEN price = 0 THEN ('10000')
		END AS purchase_price
FROM app_store_apps

SELECT DISTINCT(name), CAST(price AS MONEY),
	CASE
		WHEN CAST(price AS MONEY) > CAST('0' AS MONEY) THEN CAST(price AS MONEY) * 10000
		WHEN CAST (price AS MONEY)= CAST('0' AS MONEY) THEN ('10000')
		END AS purchase_price
FROM play_store_apps;
--Add Purchase Price Column...seth

--Attempting to use above built into subquery "table"
SELECT store_name, name, price, cust_rating,
CASE
		WHEN price > CAST('0' AS MONEY) THEN (price * 10000)
		WHEN price = CAST('0' AS MONEY) THEN ('10000')
		END AS purchase_price
FROM 
(
SELECT name, 'app_store' AS store_name, CAST(price AS MONEY), rating AS cust_rating, content_rating, primary_genre AS genre
FROM app_store_apps AS a
UNION ALL
SELECT name, 'play_store' AS store_name, CAST(price AS MONEY), rating AS cust_rating, content_rating, genres AS genre
FROM play_store_apps AS p
ORDER BY name) AS sub
ORDER BY name;
---WITH DISTINCT 16874 ROWS
---W/O DISTINCT 18037

--GROUP WINNER
SELECT a.name AS apple_store_apps, p.name AS play_store_apps,
 ROUND((a.rating+p.rating)/2,2) AS avg_rating,
 RANK() OVER (ORDER BY ROUND((a.rating+p.rating)/2,2) ) AS rank,
 (((ROUND((a.rating + p.rating) / 2,2 )) * 0.2) + 0.1) * 10 AS life_expectancy,
		CASE
			WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
			WHEN CAST (p.price AS MONEY)= CAST('0' AS MONEY) THEN ('10000')
			END AS playstore_purchase_price,
		CASE
			WHEN a.price > 0 THEN a.price * 10000::money
			WHEN a.price = 0 THEN ('10000')::money
			END AS appstore_purchase_price
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
ON p.name = a.name
WHERE a.price<='1' AND p.price<='1'
GROUP BY p.name,a.name,avg_rating,p.price,a.price,a.rating, p.rating
HAVING ROUND((a.rating+p.rating)/2,2) >= 4
ORDER BY avg_rating DESC
LIMIT 15;

--GROUP WINNER Update
SELECT a.name AS apple_store_apps, p.name AS play_store_apps, p.genres, a.content_rating,
 ROUND((a.rating+p.rating),0)/2 AS avg_rating,
(((ROUND((a.rating + p.rating),0)/2) * 0.2) + 0.1) * 10 AS life_expectancy,
		CASE
			WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
			WHEN CAST (p.price AS MONEY)= CAST('0' AS MONEY) THEN ('10000')
			END AS playstore_purchase_price,
		CASE
			WHEN a.price > 0 THEN a.price * 10000::money
			WHEN a.price = 0 THEN ('10000')::money
			END AS appstore_purchase_price,
			(10000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
	((1000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
	(((10000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) 
	 	- (1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)) :: MONEY AS expected_profit
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
ON p.name = a.name
GROUP BY p.name,a.name,avg_rating,p.price,a.price, p.genres, a.content_rating, a.rating, p.rating
HAVING ROUND((a.rating+p.rating)/2,2) >= 4
ORDER BY avg_rating DESC
LIMIT 10
