with source as (
    select * 
    from {{ source('bronze', 'erp_loc_a101') }}
),

deduped as (
    select *,
        row_number() over (
            partition by replace(cid, '-', '')
            order by cid  -- or another column if you have a better tiebreaker
        ) as rn
    from source
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
    from deduped
    where rn = 1
)

select * from cleaned