with paid as (
    select
        date,
        trim(Campaign_name)   as campaign_name,
        Channel                as channel,
        sum(Impressions)       as impressions,
        sum(Clicks)            as clicks,
        sum(Cost)               as cost,
        sum(Revenue_Paid)       as revenue_paid,
        sum(Orders_paid)        as orders_paid
    from {{ ref('int_PaidChannel_union') }}
    group by 1, 2, 3
),

ga4 as (
    select
        date,
        trim(Campaign_name)   as campaign_name,
        Channel                as channel,
        sum(Sessions)                                   as sessions,
        sum(Orders)                                      as orders_ga4,
        sum(Revenue)                                     as revenue_ga4,
        sum(Key_event_count_for_add_to_cart)             as add_to_cart,
        sum(Key_event_count_for_begin_checkout)          as begin_checkout,
        sum(Key_event_count_for_view_item)               as view_item
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