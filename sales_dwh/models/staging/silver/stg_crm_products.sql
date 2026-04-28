with source as (

    select * 
    from {{ source('bronze', 'crm_prd_info') }}

),

cleaned as (

    select
        prd_id as product_id,

        replace(substring(prd_key, 1, 5), '-', '_') as category_id,
        substring(prd_key, 7, len(prd_key)) as product_number,

        prd_nm as product_name,
        coalesce(prd_cost, 0) as cost,

        case 
            when upper(prd_line) = 'M' then 'Mountain'
            when upper(prd_line) = 'R' then 'Road'
            when upper(prd_line) = 'S' then 'Other Sales'
            when upper(prd_line) = 'T' then 'Touring'
            else 'Unknown'
        end as product_line,

        cast(prd_start_dt as date) as start_date,
        cast(prd_end_dt as date) as end_date

    from source

)

select * from cleaned