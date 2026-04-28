with source as (

    select * 
    from {{ source('bronze', 'erp_cust_az12') }}

),

cleaned as (

    select
        replace(cid, 'NAS', '') as customer_id,

        case 
            when bdate > current_date then null
            else bdate
        end as birth_date,

        case 
            when upper(trim(gen)) in ('M', 'MALE') then 'Male'
            when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
            else 'Unknown'
        end as gender

    from source

)

select * from cleaned