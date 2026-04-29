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
            when sls_order_dt = 0
                 or length(to_varchar(sls_order_dt)) != 8
            then null
            else to_date(to_varchar(sls_order_dt), 'YYYYMMDD')
        end as order_date,

        case
            when sls_ship_dt = 0
                 or length(to_varchar(sls_ship_dt)) != 8
            then null
            else to_date(to_varchar(sls_ship_dt), 'YYYYMMDD')
        end as ship_date,

        case
            when sls_due_dt = 0
                 or length(to_varchar(sls_due_dt)) != 8
            then null
            else to_date(to_varchar(sls_due_dt), 'YYYYMMDD')
        end as due_date,

        case
            when sls_sales is null
                 or sls_sales <= 0
                 or sls_sales != sls_quantity * abs(sls_price)
            then sls_quantity * abs(sls_price)
            else sls_sales
        end as sales_amount,

        sls_quantity as quantity,

        case
            when sls_price is null
                 or sls_price <= 0
            then sls_sales / nullif(sls_quantity, 0)
            else sls_price
        end as price

    from source

)

select *
from cleaned