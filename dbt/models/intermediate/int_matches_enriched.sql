with base as (
    select * from {{ ref('int_matches_unionized') }}
),

enriched as (
    select
        *,

        -- Match completion flag
        case
            when score is null then null
            when score like '%RET%' then false
            when score like '%W/O%' then false
            when score like '%DEF%' then false
            when score like '%ABD%' then false
            when score like '%UNK%' then false
            else true
        end as is_completed,

        -- Count sets played by counting space-separated tokens after stripping suffixes
        -- Only for completed matches, NULL otherwise
        case
            when score is null then null
            when score like '%RET%' or score like '%W/O%' or score like '%DEF%'
              or score like '%ABD%' or score like '%UNK%' then null
            else (
                array_length(
                    split(trim(score), ' ')
                )
            )
        end as sets_played

    from base
),

final as (
    select
        *,
        sets_played >= 3 as went_to_3rd_set,
        sets_played >= 4 as went_to_4th_set,
        sets_played = 5  as went_to_5th_set
    from enriched
)

select * from final