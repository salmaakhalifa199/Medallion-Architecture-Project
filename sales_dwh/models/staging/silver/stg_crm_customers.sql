with source as (

    select * 
    from {{ source('bronze', 'crm_cust_info') }}

),

deduped as (

    select *,
        row_number() over (
            partition by cst_id
            order by cst_create_date desc
        ) as rn
    from source
    where cst_id is not null

),

cleaned as (

    select
        cst_id as customer_id,
        cst_key as customer_number,
        trim(cst_firstname) as first_name,
        trim(cst_lastname) as last_name,

        case 
            when upper(trim(cst_marital_status)) = 'M' then 'Married'
            when upper(trim(cst_marital_status)) = 'S' then 'Single'
            else 'Unknown'
        end as marital_status,

        case 
            when upper(trim(cst_gndr)) = 'M' then 'Male'
            when upper(trim(cst_gndr)) = 'F' then 'Female'
            else 'Unknown'
        end as gender,

        cst_create_date as create_date

    from deduped
    where rn = 1

)

select * 
from cleaned