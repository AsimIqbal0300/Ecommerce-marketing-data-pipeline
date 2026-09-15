with paid as (
    select
        date,
        trim(Campaign_name)   as campaign_name,
        Channel                as channel,
        sum(cast(Impressions as float64))    as impressions,
        sum(cast(Clicks as float64))          as clicks,
        sum(Cost)                              as cost,
        sum(Revenue_paid)                      as revenue_paid,
        sum(cast(Orders_paid as float64))     as orders_paid
    from {{ ref('int_PaidChannel_union') }}
    group by 1, 2, 3
),

ga4 as (
    select
        date,
        trim(Campaign_name)   as campaign_name,
        Channel                as channel,
        sum(cast(Sessions as float64))                              as sessions,
        sum(cast(Orders as float64))                                as orders_ga4,
        sum(Revenue)                                                 as revenue_ga4,
        sum(cast(Key_event_count_for_add_to_cart as float64))       as add_to_cart,
        sum(cast(Key_event_count_for_begin_checkout as float64))    as begin_checkout,
        sum(cast(Key_event_count_for_view_item as float64))         as view_item
    from {{ ref('int_ga4_channel-currency_col') }}
    group by 1, 2, 3
)

select
    coalesce(p.date, g.date)                    as date,
    coalesce(p.campaign_name, g.campaign_name)  as campaign_name,
    coalesce(p.channel, g.channel)              as channel,
    coalesce(p.impressions, 0)                  as impressions,
    coalesce(p.clicks, 0)                       as clicks,
    coalesce(p.cost, 0)                         as cost,
    coalesce(p.revenue_paid, 0)                 as revenue_paid,
    coalesce(p.orders_paid, 0)                  as orders_paid,
    coalesce(g.sessions, 0)                     as sessions,
    coalesce(g.orders_ga4, 0)                   as orders_ga4,
    coalesce(g.revenue_ga4, 0)                  as revenue_ga4,
    coalesce(g.add_to_cart, 0)                  as add_to_cart,
    coalesce(g.begin_checkout, 0)               as begin_checkout,
    coalesce(g.view_item, 0)                    as view_item

from paid p
full outer join ga4 g
    on p.date = g.date
    and p.campaign_name = g.campaign_name
    and p.channel = g.channel