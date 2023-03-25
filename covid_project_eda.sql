SELECT *
FROM covid_deaths
WHERE continent IS NULL
ORDER BY 3,4


-- SELECT *
-- FROM covid_vaccinations
-- ORDER BY 3,4

-- Select Data that we are going to be using

SELECT location,
	   date_period,
	   total_cases,
	   new_cases,
	   total_deaths,
	   population
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
SELECT location,
	   date_period,
	   total_cases,
	   total_deaths,
	   (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location = 'United States'
ORDER BY 1,2

-- Looking at Total Cases vs population
-- Shows what percentage of population got covid
SELECT location,
	   date_period,
	   population,
	   total_cases,
	   (total_cases/population)*100 AS pop_covid_percentage
FROM covid_deaths
-- WHERE location = 'United States'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT location,
	   population,
	   MAX(total_cases) AS highest_infection_count,
	   MAX((total_cases)/population)*100 AS pop_covid_percentage
FROM covid_deaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY 1,2
ORDER BY pop_covid_percentage DESC

-- Showing countries with highest death count

SELECT location,
	   MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY 1
ORDER BY total_death_count DESC

-- Showing continents with the highest death count

SELECT continent,
	   MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY 1
ORDER BY total_death_count DESC


-- Global Numbers

SELECT date_period,
	   SUM(new_cases) AS total_new_cases,
	   SUM(new_deaths) AS total_new_deaths,
	   SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent IS NOT NULL AND new_cases <> 0
GROUP BY 1
ORDER BY 1


-- Looking at overall total cases, deaths, and death percentage to date.
SELECT --date_period,
	   SUM(new_cases) AS total_new_cases,
	   SUM(new_deaths) AS total_new_deaths,
	   SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
	   --total_deaths,
	   --(total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent IS NOT NULL 
--GROUP BY 1
ORDER BY 1


-- Looking at Total population vs Vaccinations

SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_vacc
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3

-- Creating CTE to show rolling people and percentage people vaccinated

WITH pop_vs_vac AS
(SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_vacc
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3)
				
SELECT *,
	   (rolling_people_vacc/population)*100 AS percent_pop_vacc
FROM pop_vs_vac
WHERE location = 'United States'


-- Creating CTE to show rolling people and percentage people dead

WITH pop_vs_death AS
(SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   dea.new_deaths,
	   SUM(dea.new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_dead
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3)
				
SELECT *,
	   (rolling_people_dead/population)*100 AS percent_pop_dead
FROM pop_vs_death



-- Creating a Temp Table to show rolling people and percentage people vaccinated

CREATE TEMPORARY TABLE per_pop_vacc
(
id SERIAL PRIMARY KEY,
continent text,
location text,
date_period date,
population numeric,
new_vaccinations numeric,
rolling_people_vacc numeric
);

INSERT INTO per_pop_vacc (continent, location, date_period, population, new_vaccinations, rolling_people_vacc)
SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_vacc
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3

SELECT *,
	   (rolling_people_vacc/population)*100 AS percent_population_vacc
FROM per_pop_vacc
WHERE location = 'South Korea'


-- Creating a Temp Table to show rolling people dead and percentage people dead

CREATE TEMPORARY TABLE per_pop_dead
(
id SERIAL PRIMARY KEY,
continent text,
location text,
date_period date,
population numeric,
new_deaths numeric,
rolling_people_dead numeric
);

INSERT INTO per_pop_dead (continent, location, date_period, population, new_deaths, rolling_people_dead)
SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   dea.new_deaths,
	   SUM(dea.new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_dead
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3

SELECT *,
	   (rolling_people_dead/population)*100 AS percent_population_dead
FROM per_pop_dead
WHERE location = 'South Korea'



-- Creating a View to store data for later visualizations

CREATE VIEW per_pop_vacc AS
SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_vacc
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3


CREATE VIEW per_pop_death AS
SELECT dea.continent,
	   dea.location,
	   dea.date_period,
	   dea.population,
	   dea.new_deaths,
	   SUM(dea.new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date_period) AS rolling_people_dead
FROM covid_deaths dea
JOIN covid_vaccinations vac ON (dea.location = vac.location AND dea.date_period = vac.date_period)
WHERE dea.continent IS NOT NULL 
--Order BY 2,3


