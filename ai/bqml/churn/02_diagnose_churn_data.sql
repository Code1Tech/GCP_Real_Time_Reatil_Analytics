-- Current feature distribution
SELECT
  COUNT(*) AS customers,
  COUNT(DISTINCT recency_days) AS distinct_recency_values,
  MIN(recency_days) AS minimum_recency_days,
  MAX(recency_days) AS maximum_recency_days,
  AVG(recency_days) AS average_recency_days,
  APPROX_QUANTILES(recency_days, 10) AS recency_deciles
FROM `gcp-project-usecase.retail_gold.customer_360`;

-- Existing training label distribution, if the feature table exists
SELECT
  churn_label,
  COUNT(*) AS customer_count,
  ROUND(
    100 * SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()),
    2
  ) AS percentage
FROM `gcp-project-usecase.retail_gold.ai_churn_features`
GROUP BY churn_label
ORDER BY churn_label;