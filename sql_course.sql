SELECT title,release_year FROM moviesdb.movies where studio= "marvel studios";
SELECT * FROM moviesdb.movies where title like	"%avenger%";
SELECT release_year FROM moviesdb.movies where title= "The Godfather";
SELECT distinct studio  FROM moviesdb.movies where industry= "Bollywood";
SELECT * FROM moviesdb.movies WHERE imdb_rating>= 9;
USE moviesdb;
SELECT * FROM movies WHERE imdb_rating>= 6 AND imdb_rating<=8;
SELECT * FROM movies WHERE imdb_rating BETWEEN 6 AND 8;
SELECT * FROM movies WHERE release_year= 2022 OR release_year=2019 OR release_year = 2018;
SELECT * FROM movies WHERE release_year IN (2018,2019,2022);
SELECT * FROM movies WHERE studio IN ("Marvel Studios","Zee Studios");
SELECT * FROM movies WHERE imdb_rating IS NULL;
SELECT * FROM movies WHERE imdb_rating IS NOT NULL ;
SELECT * FROM movies WHERE industry= "Bollywood" ORDER BY  imdb_rating DESC LIMIT 5;
SELECT * FROM movies WHERE industry= "Hollywood" ORDER BY  imdb_rating DESC LIMIT 5 OFFSET 2 ; 


	/*===================Summary Analytics (MIN, MAX, AVG, GROUP BY)===================*/
			
            
SELECT MIN(imdb_rating) FROM movies WHERE industry = "bollywood";
SELECT MAX(imdb_rating) FROM movies WHERE industry = "bollywood";
SELECT AVG(imdb_rating) FROM movies WHERE studio = "Marvel Studios";
SELECT ROUND(AVG(imdb_rating),2) FROM movies WHERE studio = "Marvel Studios";
SELECT ROUND(AVG(imdb_rating),2) as avg_rating FROM movies WHERE studio = "Marvel Studios"; /* to shorten header */
SELECT MIN(imdb_rating) AS min_rating,
	   MAX(imdb_rating) AS max_rating,
       ROUND(AVG(imdb_rating),2) AS avg_rating
       FROM movies where studio = "Marvel Studios" ;
SELECT industry, COUNT(*) FROM movies GROUP BY industry;
SELECT studio, COUNT(*) FROM movies GROUP BY studio;
SELECT studio, COUNT(*) AS cnt FROM movies GROUP BY studio ORDER BY cnt DESC;
SELECT 
		studio, 
			COUNT(studio) AS cnt, 
            ROUND(AVG(imdb_rating),2) as avg_rating 
		FROM movies
		WHERE studio!= ""
	    GROUP BY studio 
	ORDER BY avg_rating DESC;

select release_year,
count(*) as cnt
 from movies group by release_year order by release_year DESC;
 
 
		/*================================ HAVING Clause=================================== */
                    
                    
SELECT	release_year, COUNT(*) as movies_count FROM movies GROUP BY release_year HAVING movies_count >2 ORDER BY movies_count DESC;

/*order /* FROM---->  WHERE -----> GROUP BY----> HAVING ---> ORDER BY */

		/*======================Calculated Columns (IF, CASE, YEAR, CURYEAR)===================*/
	
SELECT * ,YEAR(CURDATE())-birth_year AS age FROM actors;

SELECT * , 
IF(currency="USD",revenue*77,revenue) AS revenue_inr,
IF(unit = "Billions", revenue*1000,revenue) as revenue_ml
from financials ;

SELECT *,
CASE 
   WHEN unit="billions" THEN revenue*1000
   WHEN unit="thousands"THEN revenue/1000
   ELSE revenue
END AS revenue_mln
FROM financials;

SELECT * ,
ROUND((((revenue-budget)/budget)*100),2) AS profit_pct
FROM financials;

		/*======================SQL Joins (INNER, LEFT, RIGHT, FULL)====================*/
        
SELECT
   movies.movie_id , title, budget, revenue, currency, unit
   FROM movies
   INNER JOIN financials
   ON movies.movie_id=financials.movie_id;
   
   				/*========= LEFT JOIN===========*/
   
SELECT
   movies.movie_id , title, budget, revenue, currency, unit
   FROM movies
   LEFT JOIN financials
   ON movies.movie_id=financials.movie_id;
   
   				/*========= RIGHT JOIN===========*/

SELECT
   financials.movie_id , title, budget, revenue, currency, unit
   FROM movies
   RIGHT JOIN financials
   ON movies.movie_id=financials.movie_id;
   
   
				/*========= FULL JOIN===========*/
SELECT
   movies.movie_id , title, budget, revenue, currency, unit
   FROM movies
   LEFT JOIN financials
   ON movies.movie_id=financials.movie_id
   UNION
   SELECT
   financials.movie_id , title, budget, revenue, currency, unit
   FROM movies
   RIGHT JOIN financials
   ON movies.movie_id=financials.movie_id;
   
         /* we can also use USING clause in place of ON only when the column name is same in both the table,
         here column name is same in both table i.e. (movie_id), so use of USING clause is better practice*/
         
SELECT
   financials.movie_id , title, budget, revenue, currency, unit
   FROM movies
   LEFT JOIN financials
   USING (movie_id);
   
								/* ============Analytics on Tables ============= */
      
SELECT movies.movie_id, title, budget, revenue, currency, unit,
CASE
     WHEN unit="thousands" THEN ROUND((revenue-budget)/1000,2)
     When unit="billions" THEN ROUND((revenue-budget)*1000,2)
     ELSE ROUND((revenue-budget),2)
END AS profit_mln
FROM movies
JOIN financials
USING (movie_id)
WHERE industry="bollywood"
ORDER BY profit_mln DESC;

                    /* =================== Join More Than Two Tables =====================*/
SELECT 
    m.movie_id, 
    m.title, 
    GROUP_CONCAT(a.name separator " | ") AS actors
FROM movies m
JOIN movie_actor ma ON m.movie_id = ma.movie_id
JOIN actors a ON ma.actor_id = a.actor_id
GROUP BY m.movie_id ;

SELECT 
				a.name,
                group_concat(m.title separator " | ") AS movies,
                COUNT(m.movie_id) AS movies_count
		FROM actors a
        JOIN movie_actor ma ON a.actor_id=ma.actor_id
        JOIN movies m ON ma.movie_id=m.movie_id
GROUP BY a.name
ORDER BY movies_count DESC;

			/*===================  Subqueries   ======================*/
            
SELECT * FROM movies
WHERE imdb_rating= (SELECT MAX(imdb_rating) FROM movies);

SELECT * FROM movies
WHERE imdb_rating= (SELECT MIN(imdb_rating) FROM movies);

SELECT * FROM movies
WHERE imdb_rating in( 
(SELECT MAX(imdb_rating) FROM movies),
(SELECT MIN(imdb_rating) FROM movies)
);

/*  STATEMENT --->  Select all the actors whose age is greater than 70 and less than 85 */

SELECT actor_name, age
FROM (SELECT name as actor_name,(year(curdate())-birth_year) AS age
		FROM actors) AS actors_age_table
WHERE age >70 AND age<85;


				/*===================  ANY, ALL Operators   ======================*/

/* STATEMENT ---> select actors who acted in any of these movies (101,110, 121) */

SELECT * FROM actors
WHERE actor_id= ANY(SELECT actor_id FROM movie_actor WHERE movie_id IN (101,110,121));

SELECT * 
from actors a
JOIN movie_actor ma on a.actor_id=ma.actor_id
having movie_id in(101,110,121);

/* STATEMENT ---> select all movies whose rating is greater than *any* of the marvel movies rating */
SELECT * FROM movies WHERE imdb_rating > ANY(SELECT imdb_rating FROM movies WHERE studio="marvel studios");

/* -- Above, can be achieved in another way too (sub query, MIN)*/
 SELECT * FROM movies WHERE imdb_rating > (
 SELECT MIN(imdb_rating) FROM movies WHERE studio="Marvel Studios"
 );


/* STATEMENT ---> select all movies whose rating is greater than *all* of the marvel movies rating */
SELECT * FROM movies WHERE imdb_rating >ALL(
SELECT imdb_rating FROM movies WHERE studio = "Marvel Studios"
);

/* -- Above, can be achieved in another way too (sub query, MAX) */
SELECT * FROM movies WHERE imdb_rating > (
SELECT MAX(imdb_rating) FROM movies WHERE studio= "Marvel Studios"
);

/* =================### Module: Co-Related Subquery ============== */

/*  Get the actor id, actor name and the total number of movies they acted in.  */

SELECT 
actor_id,
name,
(SELECT COUNT(*) FROM movie_actor WHERE actor_id=actors.actor_id) AS movie_count
FROM actors
ORDER BY movie_count DESC;


/* Above, can be achieved by using Joins too! */ 
SELECT 
a.actor_id,
a.name,
count(*) AS movie_count
FROM movie_actor ma
JOIN actors a ON ma.actor_id=a.actor_id
GROUP BY a.actor_id
ORDER BY movie_count DESC;

/* ======================== ### Module: Common Table Expression (CTE) =========================== */

/*  Select all the actors whose age is greater than 70 and less than 85 
[Previously, we have used sub-queries to solve this. Now we use CTE's] */

WITH actors_age AS (
        SELECT name AS actor_name,
        year(current_date())-birth_year AS age 
        FROM actors)
	SELECT * 
    FROM actors_age
    WHERE age > 70 AND age < 85;
    
   /* Movies that produced 500% profit and their rating was less than average rating for all movies */
   
   /* Movies that produced 500% profit */
     
SELECT * ,
     ((revenue-budget)*100)/budget AS pct_profit
FROM financials
WHERE ((revenue-budget)*100)/budget>= 500;

 /*and their rating was less than average rating for all movies */ 
 
SELECT * FROM movies
WHERE imdb_rating < (SELECT AVG(imdb_rating) FROM movies);


  /* now use SELECT * FROM() X -----------------------() Ist query
					  JOIN() Y -----------------------() IInd query 
					  ON X. movie_id = Y. movie_id-----movie_id is common column  */
                            
                            
SELECT
 X.movie_id,x.pct_profit,
 Y.title, Y.imdb_rating
   FROM(SELECT * ,
     ((revenue-budget)*100)/budget AS pct_profit
        FROM financials) X
   JOIN(SELECT * FROM movies
        WHERE imdb_rating < (SELECT AVG(imdb_rating) FROM movies)) Y
   ON X. movie_id = Y. movie_id
   WHERE pct_profit>= 500;

# CTE

/*  
with 
      X AS (),              -----------------------() Ist query
      Y AS ()               -----------------------() IInd query
SELECT
      X.movie_id,x.pct_profit,
      Y.title, Y.imdb_rating
 FROM X
 JOIN Y
 ON X. movie_id = Y. movie_id
 WHERE pct_profit>= 500;  
                                    */
                                    
with 
      X AS (SELECT * ,
            ((revenue-budget)*100)/budget AS pct_profit
            FROM financials),
      Y AS (SELECT * FROM movies
             WHERE imdb_rating < (SELECT AVG(imdb_rating) FROM movies))
SELECT
      X.movie_id,x.pct_profit,
      Y.title, Y.imdb_rating
 FROM X
 JOIN Y
 ON X. movie_id = Y. movie_id
 WHERE pct_profit>= 500;  