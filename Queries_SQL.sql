/*Lab | Making predictions with logistic regression
In this lab, you will be using the Sakila database of movie rentals.

In order to optimize our inventory, we would like to know which films will be rented next month and we are asked to create a model to predict it.

Instructions
Create a query or queries to extract the information you think may be relevant for building the prediction model. It should include some film features and some rental features.
Read the data into a Pandas dataframe.
Analyze extracted features and transform them. You may need to encode some categorical variables, or scale numerical variables.
Create a query to get the list of films and a boolean indicating if it was rented last month. This would be our target variable.
Create a logistic regression model to predict this variable from the cleaned data.
Evaluate the results.*/
USE sakila_copy_lab;
# film rented this month (yes/no)
SELECT film_id as film_id, IF(count(rental_id) > 0, 'YES', 'NO') as if_film_rented FROM rental
RIGHT JOIN inventory ON rental.inventory_id = inventory.inventory_id and rental_date >= 20050615 and rental_date <= 20050630
GROUP BY film_id
ORDER BY film_id;

# film rented last month (num of rentals)
SELECT film_id, count(rental_id) as num_films_rented FROM rental
RIGHT JOIN inventory ON rental.inventory_id = inventory.inventory_id and rental_date >= 20050515 and rental_date <= 20050530
GROUP BY film_id
ORDER BY film_id;

# film rating
SELECT film.film_id, rating from film
INNER JOIN inventory ON film.film_id = inventory.film_id
GROUP BY film_id, rating
ORDER BY film_id;

# film length
SELECT film.film_id, length from film
INNER JOIN inventory ON film.film_id = inventory.film_id
GROUP BY film_id, length
ORDER BY film_id;

# num of copies in inventory
SELECT film_id, count(inventory_id) from inventory
GROUP BY film_id
ORDER BY film_id;

# category
SELECT film_category.film_id, name as category_name from film_category
INNER JOIN category ON film_category.category_id = category.category_id
INNER JOIN inventory ON film_category.film_id = inventory.film_id
GROUP BY film_id, name
ORDER BY film_id;

-------- getting a list of films available from inventory
CREATE VIEW available_films AS SELECT distinct film_id FROM inventory;

-------- actors stuff - number of popular actors starring in the film
# popular actors, who have starred in more than 30 films

CREATE VIEW actor_film_counts AS SELECT actor_id, count(film.film_id) as num_films FROM film_actor 
RIGHT JOIN film ON film_actor.film_id = film.film_id
GROUP BY actor_id
ORDER BY actor_id;

SELECT * FROM actor_film_counts
ORDER BY num_films desc;

# popular actors, who have starred in more than 30 films
SELECT actor_id 
FROM (SELECT actor_id, count(film.film_id) as num_films FROM film_actor 
RIGHT JOIN film ON film_actor.film_id = film.film_id
GROUP BY actor_id) as sub
WHERE sub.num_films > 30;

CREATE VIEW actor_count_30 AS SELECT actor_id 
FROM  actor_film_counts
WHERE num_films > 30;

#  films with a number of popular actors starring in it

SELECT film_actor.film_id, sum(if(actor_id in (select * from actor_count_30), 1, 0)) as count_popular_actors FROM film_actor
INNER JOIN inventory ON film_actor.film_id = inventory.film_id
GROUP BY film_id
ORDER BY film_id;

----------------- Creating views
CREATE VIEW rating AS SELECT film.film_id, rating from film
INNER JOIN inventory ON film.film_id = inventory.film_id
GROUP BY film_id, rating
ORDER BY film_id;

CREATE VIEW length AS SELECT film.film_id, length from film
INNER JOIN inventory ON film.film_id = inventory.film_id
GROUP BY film_id, length
ORDER BY film_id;

CREATE VIEW number_copies AS SELECT film_id, count(inventory_id) as copies_available from inventory
GROUP BY film_id
ORDER BY film_id;

CREATE VIEW category_of_film AS SELECT film_category.film_id, name as category_name from film_category
INNER JOIN category ON film_category.category_id = category.category_id
INNER JOIN inventory ON film_category.film_id = inventory.film_id
GROUP BY film_id, name
ORDER BY film_id;

CREATE VIEW film_count_pop_actors AS SELECT film_actor.film_id, sum(if(actor_id in (select * from actor_count_30), 1, 0)) as count_popular_actors FROM film_actor
INNER JOIN inventory ON film_actor.film_id = inventory.film_id
GROUP BY film_id
ORDER BY film_id;

CREATE VIEW num_rentals_last_mo AS SELECT film_id, count(rental_id) as times_rented_last_month FROM rental
RIGHT JOIN inventory ON rental.inventory_id = inventory.inventory_id and rental_date >= 20050515 and rental_date <= 20050530
GROUP BY film_id
ORDER BY film_id;

CREATE VIEW rented_this_month_y_n AS SELECT film_id as film_id, IF(count(rental_id) > 0, 'YES', 'NO') as if_film_rented FROM rental
RIGHT JOIN inventory ON rental.inventory_id = inventory.inventory_id and rental_date >= 20050615 and rental_date <= 20050630
GROUP BY film_id
ORDER BY film_id;

SELECT rating, length, copies_available, category_name, count_popular_actors, times_rented_last_month, if_film_rented from rating
INNER JOIN length ON rating.film_id = length.film_id
INNER JOIN number_copies ON length.film_id = number_copies.film_id
INNER JOIN category_of_film ON number_copies.film_id = category_of_film.film_id
INNER JOIN film_count_pop_actors ON category_of_film.film_id = film_count_pop_actors.film_id 
INNER JOIN num_rentals_last_mo ON film_count_pop_actors.film_id = num_rentals_last_mo.film_id 
INNER JOIN rented_this_month_y_n ON  num_rentals_last_mo.film_id = rented_this_month_y_n.film_id
ORDER BY rating.film_id;