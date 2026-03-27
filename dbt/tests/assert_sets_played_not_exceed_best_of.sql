-- Sets played cannot exceed the best_of value
select *
from {{ ref('int_matches_enriched') }}
where sets_played > best_of