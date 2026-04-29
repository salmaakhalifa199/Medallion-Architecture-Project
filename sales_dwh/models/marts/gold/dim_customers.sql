with customers as (

    select * 
    from {{ ref('stg_crm_customers') }}

),

locations as (

    select * 
    from {{ ref('stg_erp_locations') }}

),

final as (

    select
        c.customer_id,
        c.customer_number,
        c.first_name,
        c.last_name,
        c.gender,
        c.marital_status,
        l.country,
        c.create_date

    from customers c
    left join locations l
        on c.customer_number = l.customer_id

)

select * 
from final