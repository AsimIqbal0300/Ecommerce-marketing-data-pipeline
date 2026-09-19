with base as (

    select distinct
        campaign_name,
        channel,

        -- ===================== MARKET =====================
        case
            when regexp_contains(lower(campaign_name), r'uae-')  then 'UAE'
            when regexp_contains(lower(campaign_name), r'ae-')   then 'UAE'
            when regexp_contains(lower(campaign_name), r'sa-')   then 'KSA'
            when regexp_contains(lower(campaign_name), r'ksa-')  then 'KSA'
            when regexp_contains(lower(campaign_name), r'kwt-')  then 'KWT'
            when regexp_contains(lower(campaign_name), r'kw-')   then 'KWT'
            when regexp_contains(lower(campaign_name), r'bah-')  then 'BAH'
            when regexp_contains(lower(campaign_name), r'bh-')   then 'BAH'
            when regexp_contains(lower(campaign_name), r'qat-')  then 'QAT'
            when regexp_contains(lower(campaign_name), r'qa-')   then 'QAT'
            when regexp_contains(lower(campaign_name), r'qtr-')  then 'QAT'
            when regexp_contains(lower(campaign_name), r'-omn-') then 'OMAN'
            else 'Other'
        end as market,

        -- ===================== CAMPAIGN TYPE =====================
        case
            when regexp_contains(lower(campaign_name), r'awareness-')                    then 'Awareness'
            when regexp_contains(lower(campaign_name), r'rnf-')                           then 'Reach & Frequency'
            when regexp_contains(lower(campaign_name), r'(youtube-|shorts-|skippable-)')  then 'Youtube'
            when regexp_contains(lower(campaign_name), r'(pulse-|reach-|boosting-)')      then 'Reach & Frequency'
            when regexp_contains(lower(campaign_name), r'-performance-max-')              then 'PMAX'
            when regexp_contains(lower(campaign_name), r'-search')                        then 'Search'
            when regexp_contains(lower(campaign_name), r'demand-')                        then 'Demand Gen'
            when regexp_contains(lower(campaign_name), r'shopping-')                      then 'Shopping'
            when regexp_contains(lower(campaign_name), r'uaci-')                          then 'App Install'
            when regexp_contains(lower(campaign_name), r'ace-')                           then 'App Engagement'

            when lower(campaign_name) = 'tiktok-performance-ae-android-en-cpi-sales-catalog-installs-unisex-june26'
                then 'Acquisition'
            when lower(campaign_name) = 'fb-performance-ae-ios14-cpi-en-unisex-catalog-april25-aem'
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-kw-en-ios14-cpi-unisex-catalog-march25-aem'
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-ae-ios14-aaa-en-cpi-unisex-march25'
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-kw-ar-ios14-cpi-unisex-catalog-nov25-aem'
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-sa-ios14-cpi-ar-nc-unisex-catalog-apr24 – skad – test'
                then 'App Install'
            when lower(campaign_name) = "fb-performance-kw-ios14-aaa-ar-nc-cpi-unisex-uploads-may''23"
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-uae-en-ios-cpi-unisex-march25-aem-dayparting'
                then 'App Install'

            when regexp_contains(lower(campaign_name), r'prospecting-')                   then 'Prospecting'
            when regexp_contains(lower(campaign_name), r'traffic-')                       then 'Traffic'
            when regexp_contains(lower(campaign_name), r'advantage-')                     then 'ASC'

            when lower(campaign_name) = 'fb-performance-ae-android-en-nc-prospecting-catalog-cpa-unisex-discounted-advantage-feb25'
                then 'Prospecting'

            when regexp_contains(lower(campaign_name), r're-')                            then 'Remarketing'

            when lower(campaign_name) = 'fb-performance-ae-ios14-aem-en-cpa-unisex-may25'
                then 'App Engagement'
            when lower(campaign_name) = 'fb-performance-ae-android-cpi-en-unisex-v3-may25'
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-qa-en-ios14-v3-unisex-cpi-catalog-aem-pur-aug25'
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-qa-en-android-cpa-unisex-v3-sept25'
                then 'App Install'
            when lower(campaign_name) = 'fb-performance-bah-ios14-cpi-ar-catalog-aem'
                then 'App Install'
            when lower(campaign_name) = 'tiktok-performance-ae-ios-en-cpi-unisex-feb26'
                then 'App Install'

            when regexp_contains(lower(campaign_name), r'-cpi-')                          then 'App Install'
            when regexp_contains(lower(campaign_name), r'-vc-')                           then 'Traffic'
            when regexp_contains(lower(campaign_name), r'-v3-')                           then 'App Install'
            when regexp_contains(lower(campaign_name), r'-cpa-')                          then 'Acquisition'

            else 'Other'
        end as campaign_type,

        -- ===================== OBJECTIVE =====================
        case
            when regexp_contains(lower(campaign_name), r'cpi-')         then 'Conversion'
            when regexp_contains(lower(campaign_name), r'traffic-')     then 'Traffic'
            when regexp_contains(lower(campaign_name), r'aem-')         then 'Conversion'
            when regexp_contains(lower(campaign_name), r'prospecting-') then 'Conversion'
            when regexp_contains(lower(campaign_name), r'advantage-')   then 'Conversion'
            when regexp_contains(lower(campaign_name), r'branding-')    then 'Awareness'
            when regexp_contains(lower(campaign_name), r'awareness-')   then 'Awareness'
            when regexp_contains(lower(campaign_name), r'performance-') then 'Conversion'
            else 'Other'
        end as objective,

        -- ===================== CATEGORY =====================
        case
            when regexp_contains(lower(campaign_name), r'[_-]unisex') then 'Unisex'
            when regexp_contains(lower(campaign_name), r'[_-]women')  then 'Women'
            when regexp_contains(lower(campaign_name), r'[_-]female') then 'Female'
            when regexp_contains(lower(campaign_name), r'[_-]men')    then 'Men'
            when regexp_contains(lower(campaign_name), r'[_-]male')   then 'Male'
            when regexp_contains(lower(campaign_name), r'[_-]kids')   then 'Kids'
            when regexp_contains(lower(campaign_name), r'[_-]beauty') then 'Beauty'
            else 'Other'
        end as category,

        -- ===================== BUDGET TYPE =====================
        case
            when regexp_contains(lower(campaign_name), r'-performance-') then 'Performance'
            when regexp_contains(lower(campaign_name), r'-branding-')    then 'Branding'
            else 'Other'
        end as budget_type

    from {{ ref('fact_combinedtable_paid_ga4') }}

)

select
    campaign_name,
    channel,
    market,
    campaign_type,
    objective,
    category,
    budget_type,

    -- ===================== FUNNEL =====================
    case
        when lower(campaign_type) = 'app install' then 'App Install'

        when lower(campaign_type) in ('prospecting', 'pmax', 'shopping', 'search', 'asc')
            then 'Acquisition'

        when lower(campaign_type) in ('remarketing', 'app engagement')
            then 'Remarketing'

        when lower(campaign_type) in ('awareness', 'reach & frequency', 'youtube', 'pulse')
            then 'Awareness'

        when lower(campaign_type) in ('traffic', 'demand gen')
            then 'Traffic'

        when lower(campaign_type) = 'acquisition' then 'Acquisition'

        else 'Other'
    end as funnel

from base