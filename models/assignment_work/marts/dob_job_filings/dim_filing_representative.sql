
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

        -- Standardize borough names
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK')
                THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX')
                THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) = 'BROOKLYN'
                THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) = 'QUEENS'
                THEN 'Queens'
            WHEN UPPER(TRIM(borough)) = 'STATEN ISLAND'
                THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Clean ZIP codes
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

        -- DOB dates
        SAFE_CAST(
            JSON_VALUE(TO_JSON_STRING(source), '$.filing_date')
            AS DATE
        ) AS filing_date,

        SAFE_CAST(
            JSON_VALUE(TO_JSON_STRING(source), '$.current_status_date')
            AS DATE
        ) AS current_status_date,

        SAFE_CAST(
            JSON_VALUE(TO_JSON_STRING(source), '$.first_permit_date')
            AS DATE
        ) AS first_permit_date,

        SAFE_CAST(
            JSON_VALUE(TO_JSON_STRING(source), '$.approved_date')
            AS DATE
        ) AS approved_date,

        SAFE_CAST(
            JSON_VALUE(TO_JSON_STRING(source), '$.signoff_date')
            AS DATE
        ) AS signoff_date,

        -- Filing representative information
        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_first_name'
        ) AS filing_representative_first_name,

        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_middle_initial'
        ) AS filing_representative_middle_initial,

        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_last_name'
        ) AS filing_representative_last_name,

        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_business_name'
        ) AS filing_representative_business_name,

        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_street_name'
        ) AS filing_representative_street_name,

        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_city'
        ) AS filing_representative_city,

        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_state'
        ) AS filing_representative_state,

        JSON_VALUE(
            TO_JSON_STRING(source),
            '$.filing_representative_zip'
        ) AS filing_representative_zip,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    WHERE NULLIF(
        TRIM(CAST(job_filing_number AS STRING)), ''
    ) IS NOT NULL
)

SELECT *
FROM cleaned

