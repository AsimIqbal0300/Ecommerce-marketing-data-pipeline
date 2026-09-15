select * except (Cost),
         except (Revenue)
        'Google' as Channel 
from {{ ref('stg_google_ads') }}