use sakila;
-- Challenge 1
-- 1. Rank films by their length and create an output table that includes;
-- the title, length, and rank columns only. 
-- Filter out any rows with null or zero values in the length column.

CREATE OR REPLACE VIEW film_length_rankings AS 
SELECT title, length,
	   RANK() OVER(ORDER BY length DESC) as Rank_num
FROM film
WHERE length IS NOT NULL AND length <> 0;

SELECT * FROM film_length_rankings;

-- 2 Rank films by length within the rating category and create an output table
--  that includes the title, length, rating and rank columns only. 
-- Filter out any rows with null or zero values in the length column.
SELECT title, length, rating,
	   RANK() OVER(PARTITION BY rating ORDER BY length DESC) as Rank_num
FROM film
WHERE length IS NOT NULL AND length <> 0;
-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, 
-- as well as the total number of films in which they have acted. 
-- Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries
CREATE OR REPLACE VIEW actor_film_counts AS
SELECT film_id,  actor_id, 
       COUNT(actor_id) OVER(PARTITION BY actor_id) AS actor_film_count
FROM film_actor 
GROUP BY film_id, actor_id
ORDER BY film_id, actor_film_count DESC;

CREATE OR REPLACE VIEW Max_actor_film_count AS 
SELECT film_id, MAX(actor_film_count) as max_count
FROM actor_film_counts
GROUP BY film_id;

SELECT 
    f.title AS film_title,
    a.actor_id,
    CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
	mafc.max_count AS num_films
FROM 
    film f
JOIN 
    film_actor fa ON f.film_id = fa.film_id
JOIN 
    actor a ON fa.actor_id = a.actor_id
JOIN 
	 Max_actor_film_count mafc ON mafc.film_id = fa.film_id;

-- ================================================================================================================================
-- Challenge 2
-- • Step 1. Retrieve the number of monthly active customers, i.e., 
--   the number of unique customers who rented a movie in each month. 

CREATE OR REPLACE VIEW monthly_active_customers AS
SELECT
    DATE_FORMAT(r.rental_date, '%Y-%m') AS rental_month,
    COUNT(DISTINCT c.customer_id) AS active_customers
FROM
    rental r
JOIN
    customer c ON r.customer_id = c.customer_id
GROUP BY
    rental_month
ORDER BY
    rental_month;
SELECT * from monthly_active_customers;

-- Step 2. Retrieve the number of active users in the previous month. 
DROP VIEW IF EXISTS Current_Prev_Customers;
CREATE VIEW Current_Prev_Customers AS(
   SELECT 
		rental_month,        -- Number of active users for the specified year and month
		active_customers,    --  Number of active customers 
		LAG(active_customers,1) OVER(ORDER BY rental_month) AS last_month_customer
   FROM monthly_active_customers
   Group by rental_month
);
-- STEP 3  Calculate the percentage change in the number of active customers between the current and previous month.
DROP VIEW IF EXISTS Percent_Change_Customers;
CREATE VIEW Percent_Change_Customers AS 
SELECT rental_month as current_month, 
active_customers, 
last_month_customer,
Round((active_customers - last_month_customer) / last_month_customer *100, 2) as Percentage_Change
FROM Current_Prev_Customers
ORDER BY current_month; 
SELECT * FROM Percent_Change_Customers;

-- Step 4. Calculate the number of retained customers every month, 
-- i.e., customers who rented movies in the current and previous months. 
DROP TABLE IF EXISTS retained_customers;
CREATE TEMPORARY TABLE IF NOT EXISTS retained_customers AS (
    SELECT 
        DATE_FORMAT(r1.rental_date, '%Y-%m') AS current_month,
        COUNT(DISTINCT r1.customer_id) AS retained_customers
    FROM rental r1
    JOIN rental r2 ON r1.customer_id = r2.customer_id
    WHERE 
        DATE_FORMAT(r1.rental_date, '%Y-%m') = DATE_FORMAT(r2.rental_date + INTERVAL 1 MONTH, '%Y-%m')
    GROUP BY 
        DATE_FORMAT(r1.rental_date, '%Y-%m')
);
SELECT * from retained_customers;
