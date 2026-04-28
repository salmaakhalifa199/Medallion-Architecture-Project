with source as (

    select * 
    from {{ source('bronze', 'crm_sales_details') }}

),

cleaned as (

    select
        sls_ord_num as order_number,
        sls_prd_key as product_number,
        sls_cust_id as customer_id,

        case 
            when sls_order_dt = 0 then null
            else to_date(cast(sls_order_dt as string), 'YYYYMMDD')
        end as order_date,

        case 
            when sls_ship_dt = 0 then null
            else to_date(cast(sls_ship_dt as string), 'YYYYMMDD')
        end as ship_date,

        case 
            when sls_due_dt = 0 then null
            else to_date(cast(sls_due_dt as string), 'YYYYMMDD')
        end as due_date,

        sls_sales as sales_amount,
        sls_quantity as quantity,
        sls_price as price

    from source

)

select * from cleaned