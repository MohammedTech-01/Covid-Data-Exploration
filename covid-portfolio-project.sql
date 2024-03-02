Select *
From CovidDeaths
where continent is not null
order by 3, 4

--Select *
--From CovidVaccinations
--order by 3, 4

-- total_deaths and total_cases should be of type float
ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT;


-- Select Data that we are going to be using
Select location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
where continent is not null
order by 1,2 

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in saudi arabia
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
where location like '%saudi%'
and continent is not null
order by 1,2 

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid-19
Select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
where location like '%saudi%'
and continent is not null
order by 1,2 

-- Looking at Countries with Highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as HighestInfectionCount, 
MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
--where location like '%saudi%'
Group by location, population
order by 4 desc

-- Showing Countries with Highest Death Count per Population
Select location, population, MAX(total_deaths) as HighestDeathsCount, 
MAX((total_deaths/population))*100 as PercentPopulationDeath
From CovidDeaths
--where location like '%saudi%'
where continent is not null
Group by location, population
order by 3 desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS
Select  sum(new_cases) as New_Cases, sum(new_deaths) as New_Deaths, sum(new_deaths)/NULLIF(SUM(new_cases), 0)*100 as DeathPercentage
From CovidDeaths
-- where location like '%saudi%'
where continent is not null
--group by date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
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
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
