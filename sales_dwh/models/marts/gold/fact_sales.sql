with sales as (

    select * from {{ ref('stg_crm_sales') }}

),

products as (

    select product_id, product_number
    from {{ ref('dim_products') }}

),

customers as (

    select customer_id, customer_number
    from {{ ref('dim_customers') }}

),

final as (

    select
        s.order_number,
        c.customer_id,
        p.product_id,
        s.order_date,
        s.ship_date,
        s.due_date,
        s.quantity,
        s.price,
        s.sales_amount

    from sales s
    left join products p
        on s.product_number = p.product_number
    left join customers c
        on s.customer_id = c.customer_id

)

select * from final