
-- ============================================================
-- PROJECT: COVID-19 GLOBAL ANALYTICS
-- PLATFORM: GOOGLE BIGQUERY
-- DESCRIPTION: DATA PREPARATION AND DIMENSIONAL MODELING
-- SOURCE: OUR WORLD IN DATA (OWID)
-- ============================================================

-- EXECUTION ORDER
-- 1. Data Preparation
-- 2. Date Dimension
-- 3. Geographic Dimension
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


-- ============================================================
-- 2. DATE DIMENSION
-- SOURCE: covid.pandemic
-- DESTINATION: covid.dim_date
-- STATUS: RECONSTRUCTED SQL
-- ============================================================

CREATE OR REPLACE TABLE `projeto-covid-514020.covid.dim_date` AS

WITH date_range AS (
    SELECT
        MIN(date) AS start_date,
        MAX(date) AS end_date
    FROM `projeto-covid-514020.covid.pandemic`
),

calendar AS (
    SELECT calendar_date AS date
    FROM date_range,
    UNNEST(GENERATE_DATE_ARRAY(start_date, end_date)) AS calendar_date
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
    date,
    EXTRACT(DAY FROM date) AS day,
    EXTRACT(MONTH FROM date) AS month,
    FORMAT_DATE('%B', date) AS month_name,
    CONCAT('Q', CAST(EXTRACT(QUARTER FROM date) AS STRING)) AS quarter,
    EXTRACT(YEAR FROM date) AS year,
    FORMAT_DATE('%Y-%m', date) AS year_month

FROM calendar;


-- ============================================================
-- 3. GEOGRAPHIC DIMENSION
-- SOURCE: covid.FullTableCovid
-- JOIN: covid.group_economic
-- DESTINATION: covid.dim_geographic
-- STATUS: RECONSTRUCTED SQL
-- ============================================================

CREATE OR REPLACE TABLE `projeto-covid-514020.covid.dim_geographic` AS

WITH country_data AS (
    SELECT
        code,
        country_adjust AS country,
        continent_adjust AS continent,
        population,

        ROW_NUMBER() OVER (
            PARTITION BY code
            ORDER BY date DESC
        ) AS row_num

    FROM `projeto-covid-514020.covid.FullTableCovid`

    WHERE geographic_level = 'Country'
)

SELECT
    c.code,
    c.continent,
    c.country,
    g.income_group AS economic_group,
    c.population

FROM country_data AS c

LEFT JOIN `projeto-covid-514020.covid.group_economic` AS g
    ON c.code = g.Code
    AND g.Year = 2025

WHERE c.row_num = 1;


-- ============================================================
-- 4. FACT TABLE
-- SOURCE: covid.FullTableCovid
-- DATE LOOKUP: covid.dim_date
-- DESTINATION: covid.fact_covid_daily
-- STATUS: RECONSTRUCTED SQL
-- ============================================================

CREATE OR REPLACE TABLE `projeto-covid-514020.covid.fact_covid_daily` AS

SELECT
    f.code,
    d.date_key,

    f.total_cases,
    f.new_cases,
    f.new_cases_smoothed,
    f.casesacum100k AS total_cases_per_100k,
    f.new_cases_smoothed100k AS new_cases_smoothed_per_100k,

    f.total_deaths,
    f.new_deaths,
    f.new_deaths_smoothed,
    f.deathacum100k AS total_deaths_per_100k,
    f.new_deaths_smoothed100k AS new_deaths_smoothed_per_100k,

    f.deathpercentageacum AS case_fatality_ratio,

    f.total_vaccinations,
    f.people_vaccinated,
    f.people_fully_vaccinated,
    f.new_vaccinations_smoothed,
    f.ratiopeoplevaccinated AS people_vaccinated_per_hundred,
    f.people_fully_vaccinated_per_hundred,
    f.new_vaccinations_smoothed_per_million

FROM `projeto-covid-514020.covid.FullTableCovid` AS f

INNER JOIN `projeto-covid-514020.covid.dim_date` AS d
    ON f.date = d.date

WHERE f.geographic_level = 'Country';


-- ============================================================
-- 5. DATA QUALITY & VALIDATION
-- PURPOSE: Validate the dimensional model
-- STATUS: VALIDATION QUERIES
-- ============================================================

-- 5.1 Fact table record count

SELECT
    COUNT(*) AS total_records
FROM `projeto-covid-514020.covid.fact_covid_daily`;


-- 5.2 Duplicate country-date combinations

SELECT
    code,
    date_key,
    COUNT(*) AS duplicate_count
FROM `projeto-covid-514020.covid.fact_covid_daily`
GROUP BY
    code,
    date_key
HAVING COUNT(*) > 1;


-- 5.3 Unmatched geographic keys

SELECT
    COUNT(*) AS unmatched_geographic_keys
FROM `projeto-covid-514020.covid.fact_covid_daily` AS f
LEFT JOIN `projeto-covid-514020.covid.dim_geographic` AS g
    ON f.code = g.code
WHERE g.code IS NULL;


-- 5.4 Unmatched date keys

SELECT
    COUNT(*) AS unmatched_date_keys
FROM `projeto-covid-514020.covid.fact_covid_daily` AS f
LEFT JOIN `projeto-covid-514020.covid.dim_date` AS d
    ON f.date_key = d.date_key
WHERE d.date_key IS NULL;


-- 5.5 Geographic dimension country count

SELECT
    COUNT(DISTINCT code) AS countries_analyzed
FROM `projeto-covid-514020.covid.dim_geographic`;

