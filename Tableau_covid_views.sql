/*

Queries used for Tableau Visualizations of The Covid Project

*/


-- 1.

SELECT SUM(new_cases) AS total_cases,
	   SUM(new_deaths) AS total_deaths,
	   SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- 2.

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location,
	   SUM(new_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL
AND location NOT IN ('World','European Union','International','High income','Upper middle income','Lower middle income','Low income')
AND new_deaths IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC


-- 3.

SELECT location,
	   population,
	   MAX(total_cases) AS highest_infection_count,
	   MAX((total_cases/population))*100 AS percent_population_infected
FROM covid_deaths
WHERE total_cases IS NOT NULL
GROUP BY 1,2
ORDER BY 4 DESC



-- 4.

SELECT location,
	   population,
	   date_period,
	   MAX(total_cases) AS highest_infection_count,
	   MAX((total_cases/population))*100 AS percent_population_infected
FROM covid_deaths
WHERE total_cases IS NOT NULL
GROUP BY 1,2,3
ORDER BY 5 DESC



-- Extra queries to check out


-- 5.


SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   MAX(COALESCE(vac.total_vaccinations,NULL, 0)) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL
GROUP BY 1,2,3,4
ORDER BY 1,2,3


-- 6. 

SELECT location,
	   date_period,
	   population,
	   COALESCE(total_cases,0) AS total_cases,
	   COALESCE(total_deaths,0) AS total_deaths
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- 7.

WITH pop_vs_vac AS
(SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   COALESCE(vac.new_vaccinations,0) AS new_vaccinations,
	   SUM(COALESCE(vac.new_vaccinations,0)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_vacc
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3)
				
SELECT *,
	   (rolling_people_vacc/population)*100 AS percent_pop_vacc
FROM pop_vs_vac
WHERE location = 'United States'







