select * except (Revenue_SAR),
      cast(Revenue_SAR as float64) * 0.98 as Revenue,
      case
         when lower(Source___Medium) = 'google / cpc' then 'Google'
         when lower(Source___Medium) in ('facebook / cpc','facebook / paid','fb / cpc','fb / paid') then 'Meta'
         else 'Others'
         end as Channel
from
    {{ ref('stg_ga4') }}         