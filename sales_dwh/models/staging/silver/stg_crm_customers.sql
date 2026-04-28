with source as (

    select * 
    from {{ source('bronze', 'crm_cust_info') }}

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

        cst_create_date

    from source
    where cst_id is not null

)

select * from cleaned