-- ============================================================
-- PROJECT: COVID-19 GLOBAL ANALYTICS
-- PLATFORM: GOOGLE BIGQUERY
-- DESCRIPTION: DATA PREPARATION AND DIMENSIONAL MODELING
-- SOURCE: OUR WORLD IN DATA (OWID)
-- ============================================================

-- EXECUTION ORDER
-- 1. Data Preparation
-- 2. Geographic Dimension
-- 3. Date Dimension
-- 4. Fact Table
-- 5. Data Quality Validation


-- ============================================================
-- 1. DATA PREPARATION
-- SOURCE: covid.pandemic
-- DESTINATION: covid.FullTableCovid
-- STATUS: ORIGINAL SQL
-- ============================================================

CREATE OR REPLACE TABLE `projeto-covid-514020.covid.FullTableCovid` AS

WITH geral AS (
    SELECT
        *,

        CASE
            WHEN country IN (
                'Africa', 'Asia', 'Europe',
                'North America', 'South America', 'Oceania'
            ) THEN 'Continent'

            WHEN country IN (
                'High-income countries',
                'Upper-middle-income countries',
                'Lower-middle-income countries',
                'Low-income countries'
            ) THEN 'Economic Group'

            WHEN code IS NOT NULL
                 AND NOT STARTS_WITH(UPPER(code), 'OWID_')
                THEN 'Country'

            ELSE NULL
        END AS geographic_level,

        CASE
            WHEN code IS NOT NULL
                 AND NOT STARTS_WITH(UPPER(code), 'OWID_')
                THEN country
            ELSE NULL
        END AS country_adjust,

        CASE
            WHEN country IN (
                'Africa', 'Asia', 'Europe',
                'North America', 'South America', 'Oceania'
            ) THEN country

            WHEN code IS NOT NULL
                 AND NOT STARTS_WITH(UPPER(code), 'OWID_')
                THEN continent

            ELSE NULL
        END AS continent_adjust,

        CASE
            WHEN country IN (
                'High-income countries',
                'Upper-middle-income countries',
                'Lower-middle-income countries',
                'Low-income countries'
            ) THEN country
            ELSE NULL
        END AS economic_group,

        SAFE_DIVIDE(total_deaths, total_cases) * 100 AS deathpercentageacum,
        SAFE_DIVIDE(total_cases, population) * 100000 AS casesacum100k,
        SAFE_DIVIDE(total_deaths, population) * 100000 AS deathacum100k,
        new_cases_smoothed_per_million * 0.1 AS new_cases_smoothed100k,
        new_deaths_smoothed_per_million * 0.1 AS new_deaths_smoothed100k,
        SAFE_DIVIDE(people_vaccinated, population) * 100 AS ratiopeoplevaccinated

    FROM `projeto-covid-514020.covid.pandemic`
)

SELECT
    code,
    date,
    geographic_level,
    country_adjust,
    continent_adjust,
    economic_group,
    population,
    total_cases,
    new_cases,
    new_cases_smoothed,
    casesacum100k,
    new_cases_smoothed_per_million,
    new_cases_smoothed100k,
    total_deaths,
    new_deaths,
    new_deaths_smoothed,
    deathacum100k,
    new_deaths_smoothed_per_million,
    new_deaths_smoothed100k,
    deathpercentageacum,
    total_vaccinations,
    people_vaccinated,
    people_fully_vaccinated,
    new_vaccinations_smoothed,
    people_fully_vaccinated_per_hundred,
    new_vaccinations_smoothed_per_million,
    ratiopeoplevaccinated

FROM geral
WHERE geographic_level IS NOT NULL;
