/*

Covid 19 Data Exploration using PostgreSQL
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Dataset source: https://ourworldindata.org/covid-deaths

*/

SELECT *
FROM covid19dths
ORDER BY 3,4

-- Select Data

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM covid19dths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows what percentage of population got Covid

SELECT Location, date, population, total_cases, 
(CAST(total_cases as FLOAT)/(population))*100 AS PercentOfPopInfected
FROM covid19dths
WHERE Location LIKE '%Philippines%'
and continent IS NOT NULL
ORDER BY 1,2;


--Looking at Countries with Highest infection rate compared to population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, 
(CAST(MAX(total_cases) as FLOAT)/(population))*100 AS PercentOfPopInfected
FROM covid19dths
--WHERE Location LIKE '%Philippines%'
GROUP BY Location, Population
ORDER BY PercentOfPopInfected DESC NULLS LAST;


--Showing the Countries with Highest Death Count per Population

SELECT Location, MAX(total_deaths) as TotalDeathCount
FROM covid19dths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC NULLS LAST;

--Showing the CONTINENT breakdown of Death Count per Population

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM covid19dths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC NULLS LAST;

--Showing the GLOBAL breakdown of Highest Death Count per Population

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM covid19dths
WHERE continent IS NULL
and location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC NULLS LAST;

-- GLOBAL NUMBERS

SELECT --date, 
SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, 
SUM(cast(new_deaths as INT))/SUM(New_cases)*100 as DeathPercentage
FROM covid19dths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2 NULLS LAST;


--Total Population vs Vaccinations
--Percentage of Population that received at least one COVID19 vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,
								 dea.Date) as RollingPeopleVaccinated
FROM covid19dths dea
JOIN covid19vac vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3;

--Use CTE to calculate RollingPeopleVaccinated in Percent (Partition by in previous query)

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,
								  dea.Date) as RollingPeopleVaccinated
FROM covid19dths dea
JOIN covid19vac vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
--ORDER BY 2,3
)
SELECT * , (RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinated_Percent
FROM PopvsVac;


-- Create TEMP Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMP TABLE PercentPopulationVaccinated(
	Continent varchar,
	Location varchar,
	Date date,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,
								  dea.Date) as RollingPeopleVaccinated
FROM covid19dths dea
JOIN covid19vac vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
--ORDER BY 2,3
);

SELECT * , (RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinated_Percent
FROM PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,
								  dea.Date) as RollingPeopleVaccinated
FROM covid19dths dea
JOIN covid19vac vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL


SELECT *
FROM PercentPopulationVaccinated
