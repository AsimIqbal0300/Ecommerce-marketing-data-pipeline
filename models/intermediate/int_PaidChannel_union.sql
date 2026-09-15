
select * from {{ ref('int_google_ads_channel-currency_col') }}

union all

select * from {{ ref('int_meta_ads_channel-currency_col') }}
