SELECT * FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT * FROM PortfolioProject..Covid_Vaccinations
--ORDER BY 3,4


SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths

SELECT Location, [date], total_cases, total_deaths, 
    (CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location like'%states%'
ORDER BY 1, 2;

--Loking at total cases vs population
--Shows what percentage of pupulation got covid

SELECT Location, [date], Population, total_cases ,
    (CONVERT(float, total_cases) / CONVERT(float, population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE total_cases IS NOT NULL
--WHERE Location like'%states%'
ORDER BY 1, 2;

--Looking at countries with Highest Infection rate compared to Population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount ,
    MAX((CONVERT(float, total_cases) / CONVERT(float, population))) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc;


--Showing Countries with DeathCount per population
SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc;


--Lets break thing down by continent
SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc;



SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY Location
ORDER BY TotalDeathCount desc;


--showing the continents with highest death count per population
SELECT continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc;

--global numbers
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int))as total_deaths, SUM(cast(new_deaths as int))/ SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
  CASE
    WHEN SUM(new_cases) = 0 THEN 0
    ELSE SUM(cast(new_deaths as int)) * 100.0 / SUM(new_cases)
  END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY date, total_cases;


--using join on table
SELECT * FROM
PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..Covid_Vaccinations AS vac
    ON dea.location=vac.location
	and dea.date=vac.date

--looking at total population vs vaccinations
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..Covid_Vaccinations AS vac
    ON dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null 
     and vac.new_vaccinations is not null
order by 2,3


--Partitioning 
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..Covid_Vaccinations AS vac
    ON dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null 
    --and vac.new_vaccinations is not null
order by 2,3


--using CTE
With PopvsVac (Continent,location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location,dea.date) AS RollingPeopleVaccinated
 -- ,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..Covid_Vaccinations AS vac
    ON dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null 
    --and vac.new_vaccinations is not null
--order by 2,3
)
SELECT *,(RollingPeopleVaccinated/population)*100
FROM PopvsVac



--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating view to store data for later visualization
DROP VIEW IF EXISTS PercentPopulationVaccinated;
Create view PercentPopulationVaccinated as
Select 
       dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths AS dea
Join PortfolioProject..Covid_Vaccinations AS vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *
From PercentPopulationVaccinated