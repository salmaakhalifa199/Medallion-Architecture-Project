with products as (

    select * 
    from {{ ref('stg_crm_products') }}

),

categories as (

    select * 
    from {{ ref('stg_erp_categories') }}

),

final as (

    select
        p.product_id,
        p.product_number,
        p.product_name,
        p.cost,
        p.product_line,
        c.cat as category,
        c.subcat as subcategory,
        c.maintenance

    from products p
    left join categories c
        on p.category_id = c.id

    where p.end_date is null

)

select * 
from final