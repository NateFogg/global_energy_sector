SELECT * FROM @companies_aws_stage LIMIT 1;

-- create companies table
CREATE OR REPLACE TABLE public.companies AS 
SELECT cast(json_flat.value ['companyId'] AS INT) AS company_id,
        value ['companyName'] AS company_name,
        value ['shortName'] AS company_name_short,
        value ['ownership'] AS ownership_type,
        value ['industries'][0] AS industry,
        value ['street1Address'] AS address,
        value ['city'] AS city,
        value ['state'] AS state,
        value ['zipcode'] AS zipcode,
        value ['country'] AS country,
        value ['phoneNumber'] AS phoneNumber,
        value ['website'] AS company_website,
        cast(value ['revenue'] AS INT) AS revenue,
        cast(value ['totalFunding'] AS INT) AS funding_total,
        cast(value ['totalFundings'] AS INT) AS funding_count,
        cast(value ['totalAcquisitions'] AS INT) AS acquisitions_count,
        cast(value ['totalCompetitors'] AS INT) AS competitors_count,
        cast(value ['totalInvestments'] AS INT) AS investments_count,
        cast(value ['founded'] AS INT) AS year_founded,
        value['statusInfo']['status'] AS statusInfo,
        cast(value ['employeeCount'] AS INT) AS employee_count,
        value['ceoDetail']['firstName'] AS ceo_first,
        value['ceoDetail']['lastName'] AS ceo_last,
        value['ceoDetail']['designation'] AS ceo_designation,
        value ['url'] AS owler_url,
        cast(value ['completenessScore'] AS INT) AS owler_completeness_score,
        cast(value ['followers'] AS INT) AS owler_followers_count
FROM(
    SELECT $1 json_data
    FROM @companies_aws_stage src
    ) companies
    , LATERAL FLATTEN(INPUT => companies.json_data) json_flat;
    
ALTER TABLE companies
ADD CONSTRAINT PK_company PRIMARY KEY (company_id);
    
-- create funding table
CREATE OR REPLACE TABLE public.funding AS     
SELECT json_flat_funding.value ['fundingRound'] AS funding_round,
        TO_DATE('01-' || (json_flat_funding.value ['fundingDate']), 'DD-Mon YYYY') AS funding_date,
        cast(json_flat_funding.value ['fundingAmount'] AS INT) AS funding_amount,
        cast(json_flat.value ['companyId'] AS INT) AS company_id
FROM(
    SELECT $1 json_data
    FROM @companies_aws_stage src
    ) companies
    , LATERAL FLATTEN(INPUT => companies.json_data) json_flat
    , LATERAL FLATTEN(INPUT => json_flat.value ['companyFundingInfo']) json_flat_funding;
    
ALTER TABLE funding
ADD CONSTRAINT PK_funding PRIMARY KEY (funding_date, funding_amount);
ALTER TABLE funding
ADD FOREIGN KEY (company_id) REFERENCES companies(company_id);

-- create acquisition table
CREATE OR REPLACE TABLE public.acquisition AS     
SELECT json_flat_acquisition.value ['companyName'] AS company_name,
        TO_DATE('01-' || (json_flat_acquisition.value ['acquisitionDate']), 'DD-Mon YYYY') AS acquisition_date,
        cast(json_flat_acquisition.value ['unDisclosed'] AS BOOLEAN) AS un_disclosed,
        cast(json_flat.value ['companyId'] AS INT) AS acquirer_id
FROM(
    SELECT $1 json_data
    FROM @companies_aws_stage src
    ) companies
    , LATERAL FLATTEN(INPUT => companies.json_data) json_flat
    , LATERAL FLATTEN(INPUT => json_flat.value ['companyAcquisitionInfo']) json_flat_acquisition;
    
ALTER TABLE acquisition
ADD CONSTRAINT PK_acquisition PRIMARY KEY (company_name, acquisition_date);
ALTER TABLE acquisition
ADD FOREIGN KEY (acquirer_id) REFERENCES companies(company_id);
    
-- create investments table
CREATE OR REPLACE TABLE public.investments AS     
SELECT json_flat_investments.value ['companyId'] AS company_id,
        json_flat_investments.value ['short_name'] AS company_name,
        json_flat_investments.value ['ownership'] AS ownership_type,
        TO_DATE(json_flat_investments.value ['investmentDate'] || cast(json_flat_investments.value ['investmentYear'] AS INT), 'Mon DD, YYYY') AS investment_date,                                   cast(json_flat_investments.value ['amount'] AS INT) AS amount,
        cast(json_flat.value ['companyId'] AS INT) AS investor_id
FROM(
    SELECT $1 json_data
    FROM @companies_aws_stage src
    ) companies
    , LATERAL FLATTEN(INPUT => companies.json_data) json_flat
    , LATERAL FLATTEN(INPUT => json_flat.value ['companies']) json_flat_investments;
    
ALTER TABLE investments
ADD CONSTRAINT PK_investments PRIMARY KEY (company_id, investment_date, amount);
ALTER TABLE investments
ADD FOREIGN KEY (investor_id) REFERENCES companies(company_id);