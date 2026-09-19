with date_bounds as (
    select 
          date('2024-01-01') as start_date,
          date_add(max(cast(date as date)), interval 1 month) as end_date
   from {{ ref('int_paid_union_ga4') }}
),
 calendar as (
    select date_range 
    from date_bounds,
    unnest(generate_date_array(start_date,end_date,interval 1 day)) as date_range
)

select date_range as date,
       extract(year from date_range) as year,
       extract(month from date_range) as month,
       format_date('%b',date_range) as month_name,
       extract(day from date_range) as day,
       format_date('%A',date_range) as day_name,
       extract(dayofweek from date_range) as day_of_week,
       extract(dayofweek from date_range) in (1,7) as weekend_days
from 
    calendar



