select * ,'Google' as Channel 
from {{ ref('stg_google_ads') }}