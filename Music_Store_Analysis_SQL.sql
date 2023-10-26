-- I created the database 'music_database' and then loaded 11 tables by restoring sql file 'Music_Store_database.sql' on this database.

-- Important insights gained using SQL Queries :


-- Who is the senior most employee based on job title?

SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1 ;

-- Which countries have the most Invoices?

select billing_country , count(*) as number_of_invoices from invoice
group by billing_country
order by count(*) desc;


-- What are top 3 values of total invoice?

SELECT total 
FROM invoice
ORDER BY total DESC
limit 3 ;


/* Which city has the best customers? We would like to throw a promotional Music Festival in the
city we made the most money.  */

select billing_city as city , sum(total) as total from invoice
group by billing_city order by total desc limit 1 ;


/* Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT c.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer c
INNER JOIN invoice i ON i.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_spending DESC
LIMIT 1;



--What is the email, first name, last name, & Genre of all Rock Music listeners?


SELECT DISTINCT email,first_name, last_name
FROM customer c
INNER JOIN invoice i ON c.customer_id = i.customer_id
INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
where track_id in 
(
SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


/* Whar are the top 10 rock bands in our dataset? Show the total track count. */

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id , artist.name
ORDER BY number_of_songs DESC
LIMIT 10;

/* Dispay the Name and Milliseconds for each track that has length longer than the average song length. 
   The longest songs should be listed first. */

SELECT name , milliseconds as length FROM track 
where milliseconds >
(select avg(milliseconds) from track)
order by length desc;


-- Find how much amount spent by each customer on the best selling artist.

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* Find out the most popular music Genre for each country. The most popular genre  here means the genre 
   with the highest amount of purchases. Display each country along with the top genre. For countries where
   the maximum number of purchases is shared return all Genres. */


WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country as country, genre.name as genre, genre.genre_id as genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC
)
SELECT country , genre , genre_id FROM popular_genre WHERE RowNo <= 1 ;


/* Find the customer that has spent the most on music for each country. 
   The customer should be displayed along with the top customer and how much they spent. */


WITH Customter_with_country AS (
		SELECT customer.customer_id as Customer_ID,first_name as First_Name, last_name as Last_Name, billing_country as Country,
		SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT Customer_ID  , First_Name , Last_Name , total_spending FROM Customter_with_country WHERE RowNo <= 1
