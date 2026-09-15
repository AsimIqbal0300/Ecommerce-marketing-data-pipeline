select * except (Cost__,Revenue__,Orders), --If a column name contains special characters (e.g. $), wrap it in backticks: `Cost_$`
         cast(Cost__ as float64) *3.672 as Cost,
         cast(Revenue__ as float64)*3.672 as Revenue_paid,
        'Google' as Channel,
        Orders as Orders_paid
from {{ ref('stg_google_ads') }}