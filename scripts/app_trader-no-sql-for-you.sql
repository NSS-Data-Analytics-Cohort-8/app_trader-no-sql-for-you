-- ### App Trader

-- Your team has been hired by a new company called App Trader to help them explore and gain insights from apps that are made available through the Apple App Store and Android Play Store. App Trader is a broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchase. 

-- Unfortunately, the data for Apple App Store apps and Android Play Store Apps is located in separate tables with no referential integrity.

-- #### 1. Loading the data
-- a. Launch PgAdmin and create a new database called app_trader.  

-- b. Right-click on the app_trader database and choose `Restore...`  

-- c. Use the default values under the `Restore Options` tab. 

-- d. In the `Filename` section, browse to the backup file `app_store_backup.backup` in the data folder of this repository.  

-- e. Click `Restore` to load the database.  

-- f. Verify that you have two tables:  
--     - `app_store_apps` with 7197 rows  
--     - `play_store_apps` with 10840 rows

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

-- (OLD CODE) vvvvvvvv
-- SELECT 
-- 	DISTINCT(name) AS app_name,
-- 	ios.price AS ios_price,
-- 	android.price AS android_price,
-- 	ios.rating AS ios_rating,
-- 	android.rating AS android_rating,
-- 	((ios.rating*0.2)+0.1)*10 AS ios_life_expectancy,
-- 	((android.rating*0.2)+0.1)*10 AS android_life_expectancy
-- FROM app_store_apps AS ios
-- INNER JOIN play_store_apps AS android
-- USING (name)
-- ORDER BY 
-- 	ios.rating DESC, 
-- 	android.rating DESC
-- LIMIT 10;   
-- (OLD CODE) ^^^^^^

-- b. Develop a Top 10 List of the apps that App Trader should buy.
-- updated 2/18/2023

SELECT 
	a.name AS apple_store_apps,
	p.name AS play_store_apps, 
	p.genres, a.content_rating,
 	ROUND((a.rating + p.rating) / 2, 2) AS avg_rating,
	(((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10 AS life_expectancy,
	CASE
		WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
		WHEN CAST (p.price AS MONEY) = CAST('0' AS MONEY) THEN ('10000')
		END AS playstore_purchase_price,
	CASE
		WHEN a.price > 0 THEN a.price * 10000::money
		WHEN a.price = 0 THEN ('10000')::money
		END AS appstore_purchase_price
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
ON p.name = a.name
WHERE a.price <= 1
AND a.content_rating <> '12+'
GROUP BY 
	p.name,
	a.name,
	avg_rating,
	p.price,
	a.price, 
	p.genres, 
	a.content_rating
HAVING ROUND((a.rating + p.rating) / 2, 2) >= 4
ORDER BY avg_rating DESC
LIMIT 10;

-- app_name(same_in_both_stores)	genres				content_rating		avg_rating		life_expectancy		purchase_price(same_from_both_stores)
-- "PewDiePie's Tuber Simulator"	"Casual"			"9+"				4.90			10.800				"$10,000.00"
-- "ASOS"							"Shopping"			"4+"				4.85			10.700				"$10,000.00"
-- "Domino's Pizza USA"				"Food & Drink"		"4+"				4.85			10.700				"$10,000.00"
-- "Egg, Inc."						"Simulation"		"4+"				4.85			10.700				"$10,000.00"	
-- "Geometry Dash Lite"				"Arcade"			"4+"				4.75			10.500				"$10,000.00"	
-- "Fernanfloo"						"Arcade"			"9+"				4.65			10.300				"$10,000.00"	
-- "Bible"							"Books & Reference"	"4+"				4.60			10.200				"$10,000.00"	
-- "Solitaire"						"Card"				"4+"				4.60			10.200				"$10,000.00"	
-- "Toy Blast"						"Puzzle"			"4+"				4.60			10.200				"$10,000.00"	
-- "Angry Birds Blast"				"Puzzle"			"4+"				4.55			10.100				"$10,000.00"	