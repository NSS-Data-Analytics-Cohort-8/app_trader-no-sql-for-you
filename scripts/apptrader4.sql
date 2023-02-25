
WITH app_trader_table AS
(SELECT
    a.name AS apple_store_apps,
    p.name AS play_store_apps,
    p.genres, a.content_rating,
    ROUND(((a.rating + p.rating) / 2)*2/2) AS avg_rating,
    ROUND((((a.rating + p.rating)/2)* 0.2) + 0.1,1)* 10 AS life_expectancy,
    CASE
        WHEN CAST(p.price AS MONEY) > CAST('0' AS MONEY) THEN CAST(p.price AS MONEY) * 10000
        WHEN CAST (p.price AS MONEY)= CAST('0' AS MONEY) THEN ('10000')
    END AS playstore_purchase_price,
    CASE
        WHEN a.price > 0 THEN a.price * 10000 :: MONEY
        WHEN a.price = 0 THEN ('10000') :: MONEY
    END AS appstore_purchase_price,
    COALESCE(
        GREATEST(CAST(CAST(p.price AS money)*10000 AS NUMERIC),a.price * 10000),'10000')::money 
        AS final_purchase_price
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

SELECT a.name, avg_rating, life_expectancy,
	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
	
	(final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
	- (final_purchase_price * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12):: MONEY AS expected_profit
FROM app_trader_table
INNER JOIN app_store_apps AS a 
ON app_trader_table.apple_store_apps = a.name
INNER JOIN play_store_apps AS p 
ON app_trader_table.play_store_apps = p.name;

--calculations
	--(10000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_revenue,
	--((1000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12) :: MONEY AS expected_cost,
	--(((10000 * (((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)
	-- 	- (1000 * ((((ROUND((a.rating + p.rating) / 2, 2)) * 0.2) + 0.1) * 10) * 12)) :: MONEY AS expected_profit
