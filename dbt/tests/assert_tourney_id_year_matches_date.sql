SELECT LEFT(tourney_id, 4), EXTRACT(YEAR FROM tourney_date), COUNT(*)
FROM `tennis-data-pipeline.tennis_prod.int_matches_enriched`
WHERE LEFT(tourney_id, 4) != CAST(EXTRACT(YEAR FROM tourney_date) AS STRING)
GROUP BY 1, 2
LIMIT 10