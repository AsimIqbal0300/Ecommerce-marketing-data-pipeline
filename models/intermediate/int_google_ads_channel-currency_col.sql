select * except (Cost__,Revenue__), --If a column name contains special characters (e.g. $), wrap it in backticks: `Cost_$`
         cast(Cost__ as float64) *3.672 as Cost,
         cast(Revenue__ as float64)*3.672 as Revenue,
        'Google' as Channel 
from {{ ref('stg_google_ads') }}