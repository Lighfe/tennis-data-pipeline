-- Best of 3 matches cannot go to a 4th set
select *
from {{ ref('int_matches_enriched') }}
where best_of = 3
  and went_to_4th_set = true