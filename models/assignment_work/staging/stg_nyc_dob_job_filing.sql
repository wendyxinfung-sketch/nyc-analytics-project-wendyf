
-- Clean and standardize DOB NOW job filings
-- One row per source job filing record

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
),

cleaned AS (
    SELECT
        -- Identifiers
        TRIM(CAST(job_filing_number AS STRING)) AS job_filing_number,

        -- Filing details
        UPPER(TRIM(CAST(filing_status AS STRING))) AS filing_status,

        -- Location: standardize borough names
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) = 'BROOKLYN' THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) = 'QUEENS' THEN 'Queens'
            WHEN UPPER(TRIM(borough)) = 'STATEN ISLAND' THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Clean ZIP code and use the same name as 311
        CASE
            WHEN REGEXP_CONTAINS(
                TRIM(COALESCE(
                    JSON_VALUE(TO_JSON_STRING(source), '$.zip'),
                    JSON_VALUE(TO_JSON_STRING(source), '$.zip_code')
                )),
                r'^\d{5}$'
            )
            THEN TRIM(COALESCE(
                JSON_VALUE(TO_JSON_STRING(source), '$.zip'),
                JSON_VALUE(TO_JSON_STRING(source), '$.zip_code')
            ))
            ELSE NULL
        END AS zip,

        -- Address
        TRIM(CAST(house_no AS STRING)) AS house_no,
        TRIM(CAST(street_name AS STRING)) AS street_name,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Remove records without a filing number
    WHERE NULLIF(TRIM(CAST(job_filing_number AS STRING)), '') IS NOT NULL
)

SELECT * FROM cleaned
