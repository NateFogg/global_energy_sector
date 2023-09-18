SELECT * FROM @companies_aws_stage LIMIT 1;

-- create companies table
CREATE OR REPLACE TABLE public.companies AS 
SELECT cast(json_flat.value ['companyId'] AS INT) AS company_id,
        cast(value ['companyName'] AS TEXT) AS company_name,
        cast(value ['shortName'] AS TEXT) AS company_name_short,
        cast(value ['ownership'] AS TEXT) AS ownership_type,
        cast(value ['industries'][0] AS TEXT) AS industry,
        cast(value ['street1Address'] AS TEXT) AS address,
        cast(value ['city'] AS TEXT) AS city,
        cast(value ['state'] AS TEXT) AS state,
        cast(value ['zipcode'] AS TEXT) AS zipcode,
        cast(value ['country'] AS TEXT) AS country,
        cast(value ['phoneNumber'] AS TEXT) AS phoneNumber,
        cast(value ['website'] AS TEXT) AS company_website,
        cast(value ['revenue'] AS INT) AS revenue,
        cast(value ['totalFunding'] AS INT) AS funding_total,
        cast(value ['totalFundings'] AS INT) AS funding_count,
        cast(value ['totalAcquisitions'] AS INT) AS acquisitions_count,
        cast(value ['totalCompetitors'] AS INT) AS competitors_count,
        cast(value ['totalInvestments'] AS INT) AS investments_count,
        cast(value ['founded'] AS INT) AS year_founded,
        cast(value['statusInfo']['status'] AS TEXT) AS statusInfo,
        cast(value ['employeeCount'] AS INT) AS employee_count,
        cast(value['ceoDetail']['firstName'] AS TEXT) AS ceo_first,
        cast(value['ceoDetail']['lastName'] AS TEXT) AS ceo_last,
        cast(value['ceoDetail']['designation'] AS TEXT) AS ceo_designation,
        cast(value ['url'] AS TEXT) AS owler_url,
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
SELECT cast(json_flat_funding.value ['fundingRound'] AS TEXT) AS funding_round,
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
SELECT cast(json_flat_acquisition.value ['companyName'] AS TEXT) AS company_name,
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
SELECT cast(json_flat_investments.value ['companyId'] AS INT) AS company_id,
        cast(json_flat_investments.value ['short_name'] AS TEXT) AS company_name,
        cast(json_flat_investments.value ['ownership'] AS TEXT) AS ownership_type,
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