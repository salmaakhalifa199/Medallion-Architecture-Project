with source as (

    select * 
    from {{ source('bronze', 'erp_loc_a101') }}

),

cleaned as (

    select
        replace(cid, '-', '') as customer_id,

        case 
            when cntry in ('US', 'USA') then 'United States'
            when cntry = 'DE' then 'Germany'
            when cntry is null or cntry = '' then 'Unknown'
            else cntry
        end as country

    from source

)

select * from cleaned