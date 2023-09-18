-- What companies, countries, and ceos, have the highest revenues?
CREATE OR REPLACE VIEW  top_ten_revenues AS
SELECT company_name, 
        country, 
        (ceo_first || ' ' || ceo_last) ceo_name,
        revenue
FROM companies
ORDER BY revenue DESC
LIMIT 10;

-- What is the average revenue of each country?
CREATE OR REPLACE VIEW country_revenue AS
SELECT country, 
        CAST(AVG(revenue) AS INT) average_revenue
FROM companies
GROUP BY country
HAVING 1 = 1
    AND country IS NOT NULL
ORDER BY AVG(revenue) DESC;

-- How many industries exist in these companies?
CREATE OR REPLACE VIEW industry_stats AS
SELECT industry, 
        COUNT(company_id) number_of_companies, 
        SUM(funding_total) sum_funding, 
        CAST(AVG(funding_total) AS INT) average_funding
FROM companies
WHERE 1 = 1
    AND industry IS NOT NULL
GROUP BY industry
ORDER BY COUNT(company_id) DESC, SUM(funding_total) DESC;

-- What are the acquisitions since 2021?
CREATE OR REPLACE VIEW recent_acquisitions AS
SELECT a.company_name as company_name,        
        c.company_name as acquirer_name, 
        c.country,
        a.acquisition_date,
        (CASE 
            WHEN a.un_disclosed = TRUE THEN 'UNDISCLOSED'
            WHEN a.un_disclosed = FALSE THEN 'DISCLOSED'
            ELSE 'UNKNOWN'
        END) STATUS
FROM acquisition a
JOIN companies c ON a.acquirer_id = c.company_id
WHERE 1 = 1
    AND YEAR(acquisition_date) BETWEEN 2021 AND 2023
ORDER BY acquisition_date DESC;
-- Get a running total and average of sent funds by month and ownership type this year.
CREATE OR REPLACE VIEW investments_2023 AS
SELECT DISTINCT MONTHNAME(investment_date) investment_month,
        MONTH(investment_date) month_number,
        ownership_type,
        SUM(amount) OVER (PARTITION BY MONTH(investment_date), ownership_type) investment_total,
        COUNT(investor_id) OVER (PARTITION BY MONTH(investment_date), ownership_type) investment_count,
        CAST(AVG(amount) OVER (PARTITION BY MONTH(investment_date), ownership_type) AS INT) investment_average
FROM investments
WHERE 1 = 1
        AND YEAR(investment_date) = 2023
        AND amount IS NOT NULL
ORDER BY MONTH(investment_date) DESC, ownership_type DESC;

-- How many IPOs have occured?
CREATE OR REPLACE VIEW ipo_history AS
WITH funding_temp AS (
    SELECT funding_date, 
            funding_amount,
            company_id
    FROM funding
    WHERE 1 = 1
    AND funding_round = 'IPO'
    AND funding_amount IS NOT NULL
)
SELECT c.company_name,
        c.country,
        c.industry,
        c.year_founded,
        c.employee_count,
        f.funding_date, 
        f.funding_amount
FROM funding_temp f
JOIN companies c ON f.company_id = c.company_id
ORDER BY f.funding_date DESC;