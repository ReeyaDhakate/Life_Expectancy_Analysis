CREATE DATABASE Life_Expectancy;
USE life_expectancy;

SELECT * FROM life_expectancy;


-- BASIC ROW CHECKS

SELECT COUNT(*) AS total_rows FROM life_expectancy;
SELECT COUNT(DISTINCT country) AS total_countries FROM life_expectancy;
SELECT MIN(year) AS min_year, MAX(year) AS max_year FROM life_expectancy;

SELECT status, COUNT(*) AS n_rows, COUNT(DISTINCT country) AS n_countries
FROM life_expectancy
GROUP BY status;



## SECTION A: TRENDS OVER TIME

-- Q1) Global Average Life Expectancy by Year

SELECT year, ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy
FROM life_expectancy
GROUP BY year
ORDER BY year;


-- Q2) Year-over-Year Change in Global Average Life Expectancy

SELECT
    year,
    ROUND(AVG(life_expectancy), 2) AS avg_le,
    ROUND(
        AVG(life_expectancy) - LAG(AVG(life_expectancy)) OVER (ORDER BY year),
    2) AS yoy_change
FROM life_expectancy
GROUP BY year
ORDER BY year;


-- Q3) Country-Level Change: 2000 vs Latest Year Available

WITH first_year AS (
    SELECT country, life_expectancy AS le_start, year AS start_year
    FROM life_expectancy
    WHERE year = (SELECT MIN(year) FROM life_expectancy)
),
last_year AS (
    SELECT country, life_expectancy AS le_end, year AS end_year
    FROM life_expectancy
    WHERE year = (SELECT MAX(year) FROM life_expectancy)
)
SELECT
    f.country,
    f.le_start,
    l.le_end,
    ROUND(l.le_end - f.le_start, 2) AS le_change
FROM first_year AS f
JOIN last_year AS l ON f.country = l.country
WHERE f.le_start IS NOT NULL AND l.le_end IS NOT NULL
ORDER BY le_change DESC;


-- Q4) Top 10 Most-Improved Countries

WITH first_year AS (
    SELECT country, life_expectancy AS le_start
    FROM life_expectancy
    WHERE year = (SELECT MIN(year) FROM life_expectancy)
),
last_year AS (
    SELECT country, life_expectancy AS le_end
    FROM life_expectancy
    WHERE year = (SELECT MAX(year) FROM life_expectancy)
)
SELECT f.country, f.le_start, l.le_end, ROUND(l.le_end - f.le_start, 2) AS le_change
FROM first_year f
JOIN last_year l ON f.country = l.country
WHERE f.le_start IS NOT NULL AND l.le_end IS NOT NULL
ORDER BY le_change DESC
LIMIT 10;


-- Q5) Top 10 Most-Declined Countries
WITH first_year AS (
    SELECT country, life_expectancy AS le_start
    FROM life_expectancy
    WHERE year = (SELECT MIN(year) FROM life_expectancy)
),
last_year AS (
    SELECT country, life_expectancy AS le_end
    FROM life_expectancy
    WHERE year = (SELECT MAX(year) FROM life_expectancy)
)
SELECT f.country, f.le_start, l.le_end, ROUND(l.le_end - f.le_start, 2) AS le_change
FROM first_year as f
JOIN last_year as l ON f.country = l.country
WHERE f.le_start IS NOT NULL AND l.le_end IS NOT NULL
ORDER BY le_change ASC
LIMIT 10;


-- Q6) Rolling 3-Year Average Life Expectancy (per country)

SELECT
    country,
    year,
    life_expectancy,
    ROUND(
        AVG(life_expectancy) OVER (
            PARTITION BY country
            ORDER BY year
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
    2) AS rolling_3yr_avg
FROM life_expectancy
ORDER BY country, year;


-- Q7) Global Trend in Child Mortality and Adult Mortality Over Time

SELECT
    year,
    ROUND(AVG(child_mortality_combined), 2) AS avg_child_mortality,
    ROUND(AVG(adult_mortality), 2) AS avg_adult_mortality
FROM life_expectancy
GROUP BY year
ORDER BY year;



## SECTION B: DEVELOPED vs DEVELOPING

-- Q8) Overall Comparison: Developed vs Developing

SELECT
    status,
    COUNT(DISTINCT country) AS n_countries,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy,
    ROUND(AVG(gdp), 0) AS avg_gdp,
    ROUND(AVG(schooling), 2) AS avg_schooling,
    ROUND(AVG(hivaids), 3) AS avg_hiv_aids,
    ROUND(AVG(adult_mortality), 1) AS avg_adult_mortality,
    ROUND(AVG(income_composition_of_resources), 3) AS avg_income_composition
FROM life_expectancy
GROUP BY status;


-- Q9) Life Expectancy Gap Between Developed and Developing, by Year

SELECT
    year,
    ROUND(MAX(CASE WHEN status = 'Developed' THEN life_expectancy END), 2) AS developed_avg,
    ROUND(MAX(CASE WHEN status = 'Developing' THEN life_expectancy END), 2) AS developing_avg
FROM (
    SELECT year, status, AVG(life_expectancy) AS life_expectancy
    FROM life_expectancy
    GROUP BY year, status
) sub
GROUP BY year
ORDER BY year;


-- Q10) Has the Gap Widened or Narrowed Over Time?

WITH yearly_gap AS (
    SELECT
        year,
        AVG(CASE WHEN status = 'Developed' THEN life_expectancy END) AS developed_avg,
        AVG(CASE WHEN status = 'Developing' THEN life_expectancy END) AS developing_avg
    FROM life_expectancy
    GROUP BY year
)
SELECT
    year,
    ROUND(developed_avg, 2) AS developed_avg,
    ROUND(developing_avg, 2) AS developing_avg,
    ROUND(developed_avg - developing_avg, 2) AS gap
FROM yearly_gap
ORDER BY year;


-- Q11) Developed vs Developing: Vaccination Coverage & Health Spending

SELECT
    status,
    ROUND(AVG(vaccination_coverage_avg), 2) AS avg_vaccination_coverage,
    ROUND(AVG(total_expenditure), 2) AS avg_total_expenditure,
    ROUND(AVG(high_health_spend), 3) AS pct_high_health_spend
FROM life_expectancy
GROUP BY status;


-- Q12) Top 10 Developing Countries Closing the Gap (Highest Life Expectancy Within Developing Group)

SELECT country, year, life_expectancy
FROM life_expectancy
WHERE status = 'Developing'
  AND year = (SELECT MAX(year) FROM life_expectancy)
ORDER BY life_expectancy DESC
LIMIT 10;



## SECTION C: CORRELATIONS WITH LIFE EXPECTANCY

-- Q13) Pearson Correlation: Schooling vs Life Expectancy

SELECT
    ((COUNT(*) * SUM(schooling * life_expectancy)) - (SUM(schooling) * SUM(life_expectancy))
    ) /
    (SQRT(COUNT(*) * SUM(POWER(schooling, 2)) - POWER(SUM(schooling), 2)) *
        SQRT(COUNT(*) * SUM(POWER(life_expectancy, 2)) - POWER(SUM(life_expectancy), 2))
    ) AS corr_schooling_life_expectancy
FROM life_expectancy
WHERE schooling IS NOT NULL AND life_expectancy IS NOT NULL;


-- Q14) Pearson Correlation: GDP vs Life Expectancy

SELECT
    ((COUNT(*) * SUM(gdp * life_expectancy)) - (SUM(gdp) * SUM(life_expectancy))
    ) /
    (SQRT(COUNT(*) * SUM(POWER(gdp, 2)) - POWER(SUM(gdp), 2)) *
	    SQRT(COUNT(*) * SUM(POWER(life_expectancy, 2)) - POWER(SUM(life_expectancy), 2))
    ) AS corr_gdp_life_expectancy
FROM life_expectancy
WHERE gdp IS NOT NULL AND life_expectancy IS NOT NULL;


-- Q15) Pearson Correlation: Adult Mortality vs Life Expectancy

SELECT
    ABS(
        ((COUNT(*) * SUM(adult_mortality * life_expectancy)) - (SUM(adult_mortality) * SUM(life_expectancy)))
        /
        (SQRT(COUNT(*) * SUM(POWER(adult_mortality, 2)) - POWER(SUM(adult_mortality), 2)) *
            SQRT(COUNT(*) * SUM(POWER(life_expectancy, 2)) - POWER(SUM(life_expectancy), 2))
		)
    ) AS corr_adult_mortality_life_expectancy
FROM life_expectancy
WHERE adult_mortality IS NOT NULL AND life_expectancy IS NOT NULL;


-- Q16) Pearson Correlation: HIV/AIDS vs Life Expectancy

SELECT
    ABS(
       ((COUNT(*) * SUM(hivaids * life_expectancy)) - (SUM(hivaids) * SUM(life_expectancy))
       ) /
	   (SQRT(COUNT(*) * SUM(POWER(hivaids, 2)) - POWER(SUM(hivaids), 2)) *
        SQRT(COUNT(*) * SUM(POWER(life_expectancy, 2)) - POWER(SUM(life_expectancy), 2))
       )
    ) AS corr_hivaids_life_expectancy
FROM life_expectancy
WHERE hivaids IS NOT NULL AND life_expectancy IS NOT NULL;


-- Q17) Pearson Correlation: Income Composition of Resources vs Life Expectancy

SELECT
    (
        (COUNT(*) * SUM(income_composition_of_resources * life_expectancy))
        - (SUM(income_composition_of_resources) * SUM(life_expectancy))
    ) /
    (
        SQRT(COUNT(*) * SUM(POWER(income_composition_of_resources, 2)) - POWER(SUM(income_composition_of_resources), 2)) *
        SQRT(COUNT(*) * SUM(POWER(life_expectancy, 2)) - POWER(SUM(life_expectancy), 2))
    ) AS corr_income_composition_life_expectancy
FROM life_expectancy
WHERE income_composition_of_resources IS NOT NULL AND life_expectancy IS NOT NULL;


-- Q18) Life Expectancy by Schooling Tier (Bucketed Correlation Check)

SELECT
    CASE
        WHEN schooling < 8  THEN '1: <8 yrs'
        WHEN schooling < 11 THEN '2: 8-11 yrs'
        WHEN schooling < 14 THEN '3: 11-14 yrs'
        ELSE '4: 14+ yrs'
    END AS schooling_tier,
    COUNT(*) AS observation_count,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy
FROM life_expectancy
WHERE schooling IS NOT NULL
GROUP BY schooling_tier
ORDER BY schooling_tier;


-- Q19) Life Expectancy by Income Composition Tier

SELECT
    CASE
        WHEN income_composition_of_resources < 0.4 THEN '1: low'
        WHEN income_composition_of_resources < 0.6 THEN '2: mid-low'
        WHEN income_composition_of_resources < 0.8 THEN '3: mid-high'
        ELSE '4: high'
    END AS income_tier,
    COUNT(*) AS observation_count,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy
FROM life_expectancy
WHERE income_composition_of_resources IS NOT NULL
GROUP BY income_tier
ORDER BY income_tier;


-- Q20) Life Expectancy by HIV/AIDS Prevalence Tier

SELECT
    CASE
        WHEN hivaids < 0.5 THEN '1: <0.5'
        WHEN hivaids < 2   THEN '2: 0.5-2'
        WHEN hivaids < 10  THEN '3: 2-10'
        ELSE '4: 10+'
    END AS hiv_tier,
    COUNT(*) AS hivaids_count ,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy
FROM life_expectancy
WHERE hivaids IS NOT NULL
GROUP BY hiv_tier
ORDER BY hiv_tier;


-- Q21) Life Expectancy by Adult Mortality Tier

SELECT
    CASE
        WHEN adult_mortality < 100 THEN '1: <100'
        WHEN adult_mortality < 200 THEN '2: 100-200'
        WHEN adult_mortality < 300 THEN '3: 200-300'
        ELSE '4: 300+'
    END AS mortality_tier,
    COUNT(*) AS adult_mortality_count ,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy
FROM life_expectancy
WHERE adult_mortality IS NOT NULL
GROUP BY mortality_tier
ORDER BY mortality_tier;


-- Q22) Life Expectancy by Vaccination Coverage Tier

SELECT
    CASE
        WHEN vaccination_coverage_avg < 60 THEN '1: <60%'
        WHEN vaccination_coverage_avg < 80 THEN '2: 60-80%'
        WHEN vaccination_coverage_avg < 90 THEN '3: 80-90%'
        ELSE '4: 90%+'
    END AS vaccination_tier,
    COUNT(*) AS vaccination_coverage,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy
FROM life_expectancy
WHERE vaccination_coverage_avg IS NOT NULL
GROUP BY vaccination_tier
ORDER BY vaccination_tier;



## SECTION D: EXPLORATORY SUMMARY

-- Q23) Overall Dataset Statistics

SELECT
    COUNT(*) AS n_rows,
    COUNT(DISTINCT country) AS countries_count,
    MIN(year) AS min_year,
    MAX(year) AS max_year,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy,
    ROUND(MIN(life_expectancy), 2) AS min_life_expectancy,
    ROUND(MAX(life_expectancy), 2) AS max_life_expectancy
FROM life_expectancy;


-- Q24) Top 10 Countries by Life Expectancy (Latest Year)

SELECT country, life_expectancy
FROM life_expectancy
WHERE year = (SELECT MAX(year) FROM life_expectancy)
  AND life_expectancy IS NOT NULL
ORDER BY life_expectancy DESC
LIMIT 10;


-- Q25) Bottom 10 Countries by Life Expectancy (Latest Year)

SELECT country, life_expectancy
FROM life_expectancy
WHERE year = (SELECT MAX(year) FROM life_expectancy)
  AND life_expectancy IS NOT NULL
ORDER BY life_expectancy ASC
LIMIT 10;


-- Q26) Outliers: Highest Adult Mortality (Latest Year)

SELECT country, adult_mortality, life_expectancy
FROM life_expectancy
WHERE year = (SELECT MAX(year) FROM life_expectancy)
  AND adult_mortality IS NOT NULL
ORDER BY adult_mortality DESC
LIMIT 5;


-- Q27) Outliers: Highest GDP per Capita (Latest Year)

SELECT country, gdp, life_expectancy
FROM life_expectancy
WHERE year = (SELECT MAX(year) FROM life_expectancy)
  AND gdp IS NOT NULL
ORDER BY gdp DESC
LIMIT 5;


-- Q28) Outliers: Lowest BMI and Highest Thinness (Latest Year)

SELECT country, bmi, thinness_avg, life_expectancy
FROM life_expectancy
WHERE year = (SELECT MAX(year) FROM life_expectancy)
  AND thinness_avg IS NOT NULL
ORDER BY thinness_avg DESC
LIMIT 10;


-- Q29) Average Life Expectancy by Life Expectancy Band

SELECT
    life_expectancy_band,
    COUNT(*) AS n_rows,
    ROUND(AVG(life_expectancy), 2) AS avg_life_expectancy
FROM life
GROUP BY life_expectancy_band
ORDER BY avg_life_expectancy DESC;


-- Q30) Countries with Most Missing/NULL Life Expectancy Records

SELECT country, COUNT(*) AS missing_records
FROM life_expectancy
WHERE life_expectancy IS NULL
GROUP BY country
ORDER BY missing_records DESC;


-- Q31) Year-by-Year Record Count (Data Completeness Check)

SELECT year, COUNT(*) AS n_records
FROM life_expectancy
GROUP BY year
ORDER BY year;


-- Q32) Rank Countries Within Each Year by Life Expectancy

SELECT
    year,
    country,
    life_expectancy,
    RANK() OVER (PARTITION BY year ORDER BY life_expectancy DESC) AS rank_in_year
FROM life_expectancy
WHERE life_expectancy IS NOT NULL
ORDER BY year, rank_in_year;


-- Q33) Average Population, GDP, and Schooling by Status 

SELECT
    status,
    ROUND(AVG(population), 0) AS avg_population,
    ROUND(AVG(gdp), 0) AS avg_gdp,
    ROUND(AVG(schooling), 2) AS avg_schooling
FROM life_expectancy
GROUP BY status;
