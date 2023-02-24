
--a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
-- For example, an app that costs $2.00 will be purchased for $20,000.
    
-- The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

SELECT a.name AS apple_store_apps, p.name AS play_store_apps,
 ROUND((a.rating+p.rating)/2,2) AS avg_rating,
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
WHERE a.price <= 1
GROUP BY p.name,a.name,avg_rating,p.price,a.price
HAVING ROUND((a.rating+p.rating)/2,2) >= 4
ORDER BY avg_rating DESC


--b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- An app that is on both app stores will make $10,000 per month.


SELECT p.name
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
ON p.name = a.name

--c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.




--d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.


--e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


