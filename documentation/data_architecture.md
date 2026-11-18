# Data Architecture

## 1. Overview

The project uses a dimensional data model developed in Google BigQuery to organize epidemiological data for analytical consumption in Power BI.

The architecture separates geographic and temporal attributes from daily COVID-19 measurements, supporting consistent analysis across countries, continents, income groups, and time periods.

## 2. Data Sources

| Source | Description |
|---|---|
| `pandemic` | Main epidemiological dataset from Our World in Data |
| `group_economic` | Country income classification data |

The economic classification dataset was integrated into the geographic dimension using a LEFT JOIN based on country codes.

## 3. Data Preparation

The source data was processed in BigQuery through SQL transformations.

The preparation stage generated `FullTableCovid`, including:

- Geographic classification of countries and aggregate records.
- Standardization of country and continent attributes.
- Derived epidemiological indicators.
- Population-adjusted cases and deaths.
- Vaccination coverage calculations.

The prepared dataset served as the basis for the final dimensional model.

## 4. Dimensional Model

The analytical model consists of two dimension tables and one fact table.

| Table | Role | Main Attributes |
|---|---|---|
| `dim_geographic` | Geographic dimension | Country, continent, income group, population |
| `dim_date` | Date dimension | Date, day, month, quarter, year |
| `fact_covid_daily` | Fact table | Cases, deaths, vaccination indicators |

### Fact Table Granularity

One record per country per date.

The final fact table contains **536,675 records** across **218 countries and territories**.

## 5. Relationships

The fact table connects to both dimensions through one-to-many relationships:

- `dim_geographic[code]` → `fact_covid_daily[code]`
- `dim_date[date_key]` → `fact_covid_daily[date_key]`

This structure enables filtering and analysis by geographic attributes and calendar periods.

## 6. Data Flow

The analytical pipeline follows this sequence:

1. Source data loaded into BigQuery.
2. SQL transformations applied to the epidemiological dataset.
3. Geographic and date dimensions structured.
4. Daily fact table generated.
5. Dimensional model connected to Power BI.
6. DAX measures and interactive reports developed.

## 7. Design Considerations

- Country-level records are used in the final fact table.
- Geographic and date dimensions provide descriptive filtering.
- Cumulative indicators require latest-valid-value aggregation rather than daily summation.
- Daily flow indicators, such as new cases and deaths, are aggregated by summation.
- Population-adjusted metrics support comparisons between countries of different sizes.

**Architecture:** Dimensional Model | BigQuery | SQL | Power BI
