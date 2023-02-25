-- -- ### App Trader

-- -- Your team has been hired by a new company called App Trader to help them explore and gain insights from apps that are made available through the Apple App Store and Android Play Store. App Trader is a broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchase. 

-- -- Unfortunately, the data for Apple App Store apps and Android Play Store Apps is located in separate tables with no referential integrity.

-- -- #### 1. Loading the data
-- -- a. Launch PgAdmin and create a new database called app_trader.  

-- -- b. Right-click on the app_trader database and choose `Restore...`  

-- -- c. Use the default values under the `Restore Options` tab. 

-- -- d. In the `Filename` section, browse to the backup file `app_store_backup.backup` in the data folder of this repository.  

-- -- e. Click `Restore` to load the database.  

-- -- f. Verify that you have two tables:  
-- --     - `app_store_apps` with 7197 rows  
-- --     - `play_store_apps` with 10840 rows

-- -- #### 2. Assumptions

-- -- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- -- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
-- -- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- -- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- -- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

-- -- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- -- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- -- - An app that is on both app stores will make $10,000 per month. 

-- -- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- -- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

-- -- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- -- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- -- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


-- -- #### 3. Deliverables

-- -- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.
-- - App Purchase Limit <=10k
-- 	- App Must Reside in Both App and Play Store
-- 	- Highest AVG Rating availible w/in Purchase Limit
-- 	- Longest Life Span Based on Highest AVG Rating 
-- 	- Secondary Conditions: Content Rating >=4+ (Customer Age Diversity), Genre(Portfolio Diversity)

-- -- b. Develop a Top 10 List of the apps that App Trader should buy.


-- FINAL GROUP QUERY
WITH app_trader_table AS
(SELECT
    a.name AS apple_store_apps,
    p.name AS play_store_apps,
    p.genres, a.content_rating,
    ROUND(((a.rating + p.rating) / 2)*2/2) AS avg_rating,
    ROUND((((a.rating + p.rating)/2)* 0.2) + 0.1,1)* 10 AS life_expectancy,
    CASE
    WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
    WHEN CAST(p.price AS MONEY) = CAST('0' AS MONEY) THEN CAST('10000' AS MONEY)
    END AS playstore_purchase_price,
    CASE
    WHEN a.price > 0 THEN CAST(a.price * 10000 AS MONEY)
    WHEN a.price = 0 THEN CAST('10000' AS MONEY)
    END AS appstore_purchase_price,
     CASE
        WHEN a.price = 0 AND CAST(p.price AS MONEY) = CAST('0' AS MONEY) THEN CAST('10000' AS MONEY)
        ELSE COALESCE(GREATEST(CAST(CAST(p.price AS money)*10000 AS NUMERIC),a.price * 10000),'10000')::money 
     END AS final_purchase_price
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
ON p.name = a.name
GROUP BY
    p.name,
    a.name,
    avg_rating,
    p.price,
    a.price,
    p.genres,
    a.content_rating,
    a.rating,
    p.rating
HAVING ROUND((a.rating + p.rating) / 2, 2) >= 4
ORDER BY avg_rating DESC)

SELECT appstore_purchase_price, playstore_purchase_price, final_purchase_price, a.name, avg_rating, life_expectancy,
	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
	(1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
	
	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
	- (1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12):: MONEY AS expected_profit
FROM app_trader_table
INNER JOIN app_store_apps AS a 
ON app_trader_table.apple_store_apps = a.name
INNER JOIN play_store_apps AS p 
ON app_trader_table.play_store_apps = p.name
GROUP BY a.name, appstore_purchase_price, playstore_purchase_price, final_purchase_price, avg_rating, life_expectancy, a.rating, p.rating
ORDER BY expected_profit DESC
LIMIT 10;


-- WITH app_trader_table AS
-- (SELECT
--     a.name AS apple_store_apps,
--     p.name AS play_store_apps,
--     p.genres, a.content_rating,
--     ROUND(((a.rating + p.rating) / 2)*2/2) AS avg_rating,
--     ROUND((((a.rating + p.rating)/2)* 0.2) + 0.1,1)* 10 AS life_expectancy,
--     CASE
--     WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
--     WHEN CAST(p.price AS MONEY) = CAST('0' AS MONEY) THEN CAST('10000' AS MONEY)
--     END AS playstore_purchase_price,
--     CASE
--     WHEN a.price > 0 THEN CAST(a.price * 10000 AS MONEY)
--     WHEN a.price = 0 THEN CAST('10000' AS MONEY)
--     END AS appstore_purchase_price,
--      COALESCE(
--         GREATEST(CAST(CAST(p.price AS money)*10000 AS NUMERIC),a.price * 10000),'10000')::money 
--         AS final_purchase_price
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name = a.name
-- GROUP BY
--     p.name,
--     a.name,
--     avg_rating,
--     p.price,
--     a.price,
--     p.genres,
--     a.content_rating,
--     a.rating,
--     p.rating
-- HAVING ROUND((a.rating + p.rating) / 2, 2) >= 4
-- ORDER BY avg_rating DESC)

-- SELECT appstore_purchase_price, playstore_purchase_price, final_purchase_price, a.name, avg_rating, life_expectancy,
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
-- 	(1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
	
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
-- 	- (1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12):: MONEY AS expected_profit
-- FROM app_trader_table
-- INNER JOIN app_store_apps AS a 
-- ON app_trader_table.apple_store_apps = a.name
-- INNER JOIN play_store_apps AS p 
-- ON app_trader_table.play_store_apps = p.name
-- GROUP BY 
-- ORDER BY expected_profit DESC;

-- WITH app_trader_table AS
-- (SELECT
--     a.name AS apple_store_apps,
--     p.name AS play_store_apps,
--     p.genres, a.content_rating,
--     ROUND(((a.rating + p.rating) / 2)*2/2) AS avg_rating,
--     ROUND((((a.rating + p.rating)/2)* 0.2) + 0.1,1)* 10 AS life_expectancy,
--     CASE
--     WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
--     WHEN CAST(p.price AS MONEY) = CAST('0' AS MONEY) THEN CAST('10000' AS MONEY)
--     END AS playstore_purchase_price,
--     CASE
--     WHEN a.price > 0 THEN CAST(a.price * 10000 AS MONEY)
--     WHEN a.price = 0 THEN CAST('10000' AS MONEY)
--     END AS appstore_purchase_price,
--     COALESCE(
--         NULLIF(CAST(a.price * 10000 AS money), CAST('0' AS MONEY)),
--         NULLIF(CAST(CAST(p.price AS money)*10000 AS money), CAST('0' AS MONEY)),
--         '10000'::money
--     ) AS final_purchase_price
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name = a.name
-- GROUP BY
--     p.name,
--     a.name,
--     avg_rating,
--     p.price,
--     a.price,
--     p.genres,
--     a.content_rating,
--     a.rating,
--     p.rating
-- --HAVING ROUND((a.rating + p.rating) / 2, 2) >= 4
-- ORDER BY avg_rating DESC)

-- SELECT appstore_purchase_price, playstore_purchase_price, final_purchase_price, a.name, avg_rating, life_expectancy,
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
	
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
-- 	- (final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12):: MONEY AS expected_profit
-- FROM app_trader_table
-- INNER JOIN app_store_apps AS a 
-- ON app_trader_table.apple_store_apps = a.name
-- INNER JOIN play_store_apps AS p 
-- ON app_trader_table.play_store_apps = p.name
-- ORDER BY expected_profit;


-- WITH app_trader_table AS
-- (SELECT
--     a.name AS apple_store_apps,
--     p.name AS play_store_apps,
--     p.genres, a.content_rating,
--     ROUND(((a.rating + p.rating) / 2)*2/2) AS avg_rating,
--     ROUND((((a.rating + p.rating)/2)* 0.2) + 0.1,1)* 10 AS life_expectancy,
--     CASE
--     WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
--     WHEN CAST(p.price AS MONEY) = CAST('0' AS MONEY) THEN CAST('10000' AS MONEY)
-- END AS playstore_purchase_price,
-- CASE
--     WHEN a.price > 0 THEN CAST(a.price * 10000 AS MONEY)
--     WHEN a.price = 0 THEN CAST('10000' AS MONEY)
-- END AS appstore_purchase_price,
--     COALESCE(
--         GREATEST(CAST(CAST(p.price AS money)*10000 AS NUMERIC),a.price * 10000),'10000')::money
--         AS final_purchase_price
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name = a.name
-- GROUP BY
--     p.name,
--     a.name,
--     avg_rating,
--     p.price,
--     a.price,
--     p.genres,
--     a.content_rating,
--     a.rating,
--     p.rating
-- --HAVING ROUND((a.rating + p.rating) / 2, 2) >= 4
-- ORDER BY avg_rating DESC)
-- SELECT appstore_purchase_price, playstore_purchase_price, final_purchase_price, a.name, avg_rating, life_expectancy,
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
	
-- 	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
-- 	- (final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12):: MONEY AS expected_profit
-- FROM app_trader_table
-- INNER JOIN app_store_apps AS a
-- ON app_trader_table.apple_store_apps = a.name
-- INNER JOIN play_store_apps AS p
-- ON app_trader_table.play_store_apps = p.name;
-- --george calculations
-- 	--(10000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
-- 	--((1000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
-- 	--(((10000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
-- 	-- 	- (1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)) :: MONEY AS expected_profit
-- 	WITH c1 AS (
-- SELECT
-- 	a.name, 	
-- 	ROUND((a.rating + p.rating), 0)/2 AS avg_rating,
-- 	(((ROUND((a.rating + p.rating),0)/2) * 0.2) + 0.1) * 10 AS life_expectancy
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name=a.name),
-- c2 AS (
-- SELECT 	
-- 	a.name,
-- 	CASE
-- 		WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
-- 		WHEN CAST (p.price AS MONEY)= CAST('0' AS MONEY) THEN ('10000')
-- 		END AS playstore_purchase_price,
-- 	CASE
-- 		WHEN a.price > 0 THEN a.price * 10000 :: MONEY
-- 		WHEN a.price = 0 THEN ('10000') :: MONEY
-- 		END AS appstore_purchase_price,
-- 	CASE
-- 		WHEN CAST(p.price AS MONEY) > a.price::MONEY THEN p.price
-- 		WHEN CAST(p.price AS MONEY) < a.price::MONEY THEN '19900.00'
-- 		WHEN CAST (p.price AS MONEY) = a.price::MONEY THEN p.price
-- 		END AS final_purchase_price
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name=a.name),
-- c3 AS (
-- 	SELECT
-- 	a.name,
--   	(10000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
--    	((1000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
--    	(((10000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
--    	 	- (1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)) :: MONEY AS expected_profit
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name=a.name)
-- SELECT
-- 	p.name,
-- 	a.name,
-- 	c1.avg_rating,
-- 	c1.life_expectancy,
-- 	c2.playstore_purchase_price,
-- 	c2.appstore_purchase_price,
-- 	c2.final_purchase_price,
-- 		c3.expected_revenue,
--  		c3.expected_cost,
-- 	 	c3.expected_profit
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name=a.name
-- INNER JOIN c1
-- ON a.name = c1.name
-- INNER JOIN c2
-- ON a.name = c2.name
-- INNER JOIN c3
-- ON a.name = C3.name
-- GROUP BY
-- 	p.name,
-- 	a.name,
-- 	a.rating,
-- 	p.rating,
-- 	c1.avg_rating,
-- 	c1.life_expectancy,
-- 	c2.playstore_purchase_price,
-- 	c2.appstore_purchase_price,
-- 	c2.final_purchase_price,
-- 	c3.expected_revenue,
-- 	c3.expected_cost,
-- 	c3.expected_profit
-- HAVING ROUND((a.rating + p.rating) / 2, 2) >= 4
-- --ORDER BY avg_rating DESC
-- ORDER BY expected_profit DESC
-- LIMIT 10;









-- -- SELECT 
-- a.name AS apple_store_apps, 
-- p.name AS play_store_apps, 
-- p.genres, 
-- a.content_rating,
-- ROUND((a.rating+p.rating)/2,2) AS avg_rating, (((ROUND((a.rating + p.rating) / 2,2)) * 0.2) + 0.1) * 10 AS life_expectancy,
-- 		CASE
-- 			WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
-- 			WHEN CAST (p.price AS MONEY)= CAST('0' AS MONEY) THEN ('10000')
-- 			END AS playstore_purchase_price,
-- 		CASE
-- 			WHEN a.price > 0 THEN a.price * 10000::money
-- 			WHEN a.price = 0 THEN ('10000')::money
-- 			END AS appstore_purchase_price,
-- 	(10000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
-- 	((1000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
-- 	(((10000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) 
-- 	 	- (1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)) :: MONEY AS expected_profit
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name = a.name
-- WHERE a.content_rating <> '12+'
-- GROUP BY p.name,a.name,avg_rating,p.price,a.price, p.genres, a.content_rating
-- HAVING ROUND((a.rating+p.rating)/2,2) >= 4
-- ORDER BY expected_revenue DESC
-- LIMIT 10;


-- --Old Code Below
-- SELECT 
-- 	a.name AS apple_store_apps,
-- 	p.name AS play_store_apps,
--  	ROUND((a.rating+p.rating)/2,2) AS avg_rating, (((ROUND((a.rating + p.rating) / 2,2)) * 0.2) + 		0.1)* 10 AS life_expectancy, 
-- 		CASE
-- 			WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
-- 			WHEN CAST (p.price AS MONEY)= CAST('0' AS MONEY) THEN ('10000')
-- 			END AS playstore_purchase_price,
-- 		CASE
-- 			WHEN a.price > 0 THEN a.price * 10000::money
-- 			WHEN a.price = 0 THEN ('10000')::money
-- 			END AS appstore_purchase_price
-- FROM play_store_apps AS p
-- INNER JOIN app_store_apps AS a
-- ON p.name = a.name
-- GROUP BY p.name,a.name,avg_rating,p.price,a.price, p.genres, a.content_rating
-- HAVING ROUND((a.rating+p.rating)/2,2) >= 4

-- LIMIT 10




-- SELECT name, 'play_store' AS store_name, CAST(rating AS NUMERIC), CAST(price AS MONEY), genres AS genre 
-- FROM play_store_apps AS p
-- WHERE rating IS NOT NULL
-- 	AND rating > 4.9
-- UNION ALL
-- SELECT name, 'app_store' AS store_name, CAST(rating AS NUMERIC), CAST(price AS MONEY), primary_genre AS genre
-- FROM app_store_apps AS a
-- WHERE rating IS NOT NULL
-- 	AND rating > 4.9
-- GROUP BY name, rating, price, genre
-- ORDER BY rating, price;

-- SELECT 'app_store' AS store_name,name, rating, CAST(price AS MONEY)
-- FROM app_store_apps
-- UNION ALL
-- SELECT 'play_store' AS store_name,name, rating, CAST(price AS MONEY)
-- FROM play_store_apps;

-- SELECT a.name AS apple_name, p.name AS playstore_name, a.rating AS apple_rating, p.rating AS playstore_rating, a.price AS apple_price, p.price AS playstore_price
-- FROM app_store_apps AS a, play_store_apps AS p
-- WHERE a.name=p.name AND a.rating=p.rating AND CAST(a.price AS MONEY)=CAST(p.price AS MONEY);

-- SELECT DISTINCT(a.name) AS apple_name, DISTINCT(p.name) AS playstore_name, a.rating AS apple_rating, p.rating AS playstore_rating, a.price AS apple_price, p.price AS playstore_price
-- FROM app_store_apps AS a, play_store_apps AS p
-- WHERE a.name=p.name AND a.rating=p.rating AND CAST(a.price AS MONEY)=CAST(p.price AS MONEY);

-- LIMIT 10

-- -- -- updated 2/18/2023
