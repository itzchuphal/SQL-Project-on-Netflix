select * from netflix;


-- 1. Count the number of Movies vs TV Shows


select type, count(*)
from netflix
group by type;


-- 2. Find the most common rating for movies and TV shows


with ratings as
		(select type, rating, count(*) 
		, rank() over(partition by type order by  count(*) desc) as rnk
		from netflix
		group by type, rating)
select type, rating
from ratings
where rnk = 1;


-- 3. List all movies released in a specific year (e.g., 2020)


with cte as 
		(select release_year, title
		, rank() over(partition by release_year ) as rnk
		from netflix
		where type = 'Movie')
select release_year, title
from cte
order by release_year;


-- 4. Find the top 5 countries with the most content on Netflix


select unnest(string_to_array(country, ',')) as country, count(*) as total_content
from netflix
group by unnest(string_to_array(country, ',')) 
order by 2 desc;


-- 5. Identify the longest movie


with cte as 
		(select title, max(replace(duration, 'min', '')::int) as runtime
		from netflix
		where type = 'Movie'
		and duration is not null
		group by title),
	 final as 
	    (select *
		, rank() over(order by runtime desc) as rnk
		from cte)
select title, runtime 
from final
where rnk = 1;


-- 6. Find content added in the last 5 years


select title, release_year
from netflix
where extract(year from current_date) - release_year::int <= 5
order by 2; 


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!


select type, title, director
from netflix
where director = 'Rajiv Chilaka';


-- 8. List all TV shows with more than 5 seasons


select title, left(duration, 2) as total_seasons
from netflix
where type = 'TV Show'
and left(duration, 2)::int > 5;


-- 9. Count the number of content items in each genre


select trim(unnest(string_to_array(listed_in, ','))) as genre, count(*)
from netflix
group by 1
order by 2 desc;


-- 10.Find each year and the average numbers of content release in India on netflix. Return top 5 year with highest avg content release! 


with cte as 
		(select release_year, unnest(string_to_array(country, ',')) as country, count(1) as total
		from netflix
		group by 1,2
		order by 2),
	 cte2 as 
		(select release_year, round(avg(total),2) as avg_releases
		, rank() over(order by round(avg(total),2) desc ) as rnk
		from cte
		where country = 'India'
		group by release_year)
select release_year, avg_releases
from cte2
where rnk < 6;


-- 11. List all movies that are documentaries


with cte as 
		(select title, trim(unnest(string_to_array(listed_in, ','))) as genre
		from netflix
		where type = 'Movie')
select title
from cte
where upper(genre) = 'DOCUMENTARIES';


-- 12. Find all content without a director


select type, title
from netflix
where director is null;


13. Find how many movies actor 'Salman Khan' appeared in last 10 years!


select title, string_to_array(casts, ',') as actors, release_year
from netflix
where string_to_array(casts, ',')::varchar like '%Salman Khan%'
and extract(year from current_date) - release_year <= 10;


-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.


with cte as 
		(select title, string_to_array(country, ',') as country, trim(unnest(string_to_array(casts, ','))) as actors
		from netflix
		where string_to_array(country, ',')::varchar like '%India%'
		and type = 'Movie'),
	 cte2 as	
	    (select actors, count(1) as total_movies
		, dense_rank() over(order by count(1) desc ) as rnk
		from cte
		group by actors)
select actors, total_movies
from cte2
where rnk < 11
order by 2 desc;



/*
15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
   the description field. Label content containing these keywords as 'Bad' and all other 
   content as 'Good'. Count how many items fall into each category.*/


select case when upper(description) like '%KILL%' 
            or upper(description) like '%VIOLENCE%'
       then 'Bad'
	   else 'Good'
	   end as category
, type
, count(1) as total
from netflix
group by type
case when upper(description) like '%KILL%' 
          or upper(description) like '%VIOLENCE%'
          then 'Bad'
	      else 'Good'
	      end as category
order by 2;