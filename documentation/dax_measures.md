# Power BI & DAX Documentation

## 1. Overview

Microsoft Power BI was used to develop the analytical model, define key performance indicators (KPIs), and build interactive dashboards.

DAX measures were designed to ensure consistent calculations across geographic, temporal, and income group analyses.

## 2. Data Model

The Power BI model follows a dimensional structure with three tables:

| Table | Role |
|---|---|
| `dim_geographic` | Geographic and economic attributes |
| `dim_date` | Calendar and time attributes |
| `fact_covid_daily` | Daily epidemiological and vaccination data |

Both dimensions have one-to-many relationships with the fact table.

## 3. Key Measures

The following measures represent the main analytical indicators developed in the report.

| Measure | Calculation Logic |
|---|---|
| Total Cases | Sum of the latest valid cumulative cases per country |
| Total Deaths | Sum of the latest valid cumulative deaths per country |
| Case Fatality Rate | Total deaths divided by total confirmed cases |
| New Cases | Sum of daily reported cases |
| New Deaths | Sum of daily reported deaths |
| People Vaccinated | Sum of the latest valid vaccinated population per country |
| Fully Vaccinated | Sum of the latest valid fully vaccinated population per country |
| Vaccination Coverage | People vaccinated divided by population |
| Fully Vaccinated Coverage | Fully vaccinated people divided by population |
| Deaths per 100K People | Total deaths divided by population, multiplied by 100,000 |

## 4. Aggregation Methodology

Different calculation approaches were applied depending on the nature of each indicator.

### Cumulative Indicators

Cumulative values represent the latest available total for each country within the selected context.

They must not be summed across daily records, as this would result in double counting.

The model uses the latest valid observation per country for cumulative cases, deaths, and vaccination totals.

### Daily Indicators

Daily reported cases and deaths are aggregated using the sum of daily observations.

Smoothed daily indicators are calculated using averages across daily values.

### Population-Adjusted Indicators

Mortality and vaccination coverage metrics are calculated relative to population.

These indicators support comparisons between countries with different population sizes.

## 5. Analytical Features

The Power BI report includes:

- KPI cards for global epidemiological and vaccination indicators.
- Geographic comparisons across continents and countries.
- Country rankings based on cumulative and population-adjusted mortality.
- Scatter analysis comparing vaccination coverage and mortality.
- Time-based analysis of reported and cumulative deaths.
- Income group comparisons across health outcomes and vaccination coverage.
- Interactive filtering by continent and economic group.

## 6. Report Structure

The report contains three main pages:

| Page | Analytical Focus |
|---|---|
| Global Overview | Global pandemic trends, mortality, and vaccination |
| COVID-19: Income & Health Outcomes | Comparison across country income groups |
| Methodology & Data | Data architecture, metric definitions, and limitations |

## 7. Calculation Considerations

- Cumulative indicators use the latest valid observation per country.
- Daily flows are aggregated by summation.
- Missing observations are not automatically treated as zero.
- Case Fatality Rate (CFR) is not equivalent to Infection Fatality Rate (IFR).
- Population-adjusted indicators use the population reference available in the geographic dimension.

**Technology:** Microsoft Power BI | DAX | Power Query
