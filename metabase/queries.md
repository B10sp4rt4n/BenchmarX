# BenchmarX - Metabase Queries
# SQL queries designed for Metabase dashboards and reports

## Query 1: Vendor Rankings by Context
```sql
-- Dashboard: Main Rankings View
-- Purpose: Show vendor rankings for each context with key metrics

SELECT 
    cp.name AS context,
    cp.industry,
    cp.company_size,
    v.name AS vendor,
    v.vendor_type,
    sr.score_percentage,
    sr.total_score,
    sr.detection_active_count AS active,
    sr.detection_dynamic_count AS dynamic,
    sr.detection_no_evid_count AS no_evidence,
    RANK() OVER (PARTITION BY cp.name ORDER BY sr.score_percentage DESC) AS rank
FROM scored_results sr
JOIN vendors v ON sr.vendor_id = v.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
ORDER BY cp.name, rank;
```

## Query 2: Attack Category Heatmap
```sql
-- Dashboard: Risk Heatmap
-- Purpose: Visualize coverage by category for each vendor

SELECT 
    v.name AS vendor,
    ac.name AS category,
    ac.mitre_tactic,
    COUNT(a.id) AS total_attacks,
    SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END) AS active_detections,
    SUM(CASE WHEN dr.detection_state = 'DYNAMIC' THEN 1 ELSE 0 END) AS dynamic_detections,
    SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END) AS no_evidence,
    ROUND(
        (SUM(CASE WHEN dr.detection_state IN ('ACTIVE', 'DYNAMIC') THEN 1 ELSE 0 END)::NUMERIC / 
         COUNT(a.id) * 100), 2
    ) AS coverage_percentage
FROM vendors v
CROSS JOIN attack_categories ac
LEFT JOIN attacks a ON ac.id = a.category_id
LEFT JOIN detection_results dr ON a.id = dr.attack_id AND dr.vendor_id = v.id
GROUP BY v.name, ac.name, ac.mitre_tactic
ORDER BY v.name, coverage_percentage DESC;
```

## Query 3: Vendor Comparison Matrix
```sql
-- Dashboard: Side-by-Side Comparison
-- Purpose: Compare multiple vendors across all attack categories

SELECT 
    ac.name AS category,
    ac.mitre_tactic,
    v.name AS vendor,
    COUNT(a.id) AS total_attacks,
    SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END) AS active,
    SUM(CASE WHEN dr.detection_state = 'DYNAMIC' THEN 1 ELSE 0 END) AS dynamic,
    SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END) AS no_evidence,
    ROUND(
        (SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END)::NUMERIC / 
         COUNT(a.id) * 100), 2
    ) AS active_percentage
FROM attack_categories ac
CROSS JOIN vendors v
LEFT JOIN attacks a ON ac.id = a.category_id
LEFT JOIN detection_results dr ON a.id = dr.attack_id AND dr.vendor_id = v.id
GROUP BY ac.name, ac.mitre_tactic, v.name
ORDER BY ac.name, active_percentage DESC;
```

## Query 4: Context Weight Impact Analysis
```sql
-- Dashboard: Weight Impact
-- Purpose: Show how context weights affect vendor rankings

SELECT 
    cp.name AS context,
    ac.name AS category,
    COALESCE(cw.weight, 1.0) AS weight,
    cw.rationale,
    COUNT(DISTINCT v.id) AS affected_vendors,
    AVG(sr.score_percentage) AS avg_score_in_context
FROM context_profiles cp
CROSS JOIN attack_categories ac
LEFT JOIN context_weights cw ON cp.id = cw.context_profile_id AND ac.id = cw.attack_category_id
LEFT JOIN scored_results sr ON cp.id = sr.context_profile_id
LEFT JOIN vendors v ON sr.vendor_id = v.id
WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
GROUP BY cp.name, ac.name, cw.weight, cw.rationale
ORDER BY cp.name, cw.weight DESC NULLS LAST;
```

## Query 5: Detection State Distribution
```sql
-- Dashboard: Detection Quality Overview
-- Purpose: Overall view of detection quality across all vendors

SELECT 
    v.name AS vendor,
    v.vendor_type,
    COUNT(*) AS total_detections,
    SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END) AS active,
    SUM(CASE WHEN dr.detection_state = 'DYNAMIC' THEN 1 ELSE 0 END) AS dynamic,
    SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END) AS no_evidence,
    ROUND(
        (SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END)::NUMERIC / 
         COUNT(*) * 100), 2
    ) AS active_percentage,
    ROUND(
        (SUM(CASE WHEN dr.detection_state IN ('ACTIVE', 'DYNAMIC') THEN 1 ELSE 0 END)::NUMERIC / 
         COUNT(*) * 100), 2
    ) AS total_coverage_percentage
FROM vendors v
LEFT JOIN detection_results dr ON v.id = dr.vendor_id
GROUP BY v.name, v.vendor_type
ORDER BY total_coverage_percentage DESC;
```

## Query 6: Top Gaps by Vendor
```sql
-- Dashboard: Security Gaps
-- Purpose: Identify critical detection gaps per vendor

SELECT 
    v.name AS vendor,
    a.name AS attack,
    ac.name AS category,
    a.severity,
    a.mitre_technique_id,
    dr.detection_state,
    CASE 
        WHEN a.severity = 'CRITICAL' AND dr.detection_state = 'NO_EVID' THEN 'High Priority Gap'
        WHEN a.severity = 'HIGH' AND dr.detection_state = 'NO_EVID' THEN 'Medium Priority Gap'
        WHEN dr.detection_state = 'NO_EVID' THEN 'Low Priority Gap'
        ELSE 'Covered'
    END AS gap_priority
FROM vendors v
LEFT JOIN detection_results dr ON v.id = dr.vendor_id
LEFT JOIN attacks a ON dr.attack_id = a.id
LEFT JOIN attack_categories ac ON a.category_id = ac.id
WHERE dr.detection_state = 'NO_EVID' OR dr.detection_state IS NULL
ORDER BY 
    CASE a.severity 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        ELSE 4 
    END,
    v.name;
```

## Query 7: Ranking Changes Over Time
```sql
-- Dashboard: Trend Analysis
-- Purpose: Track how vendor rankings change over different test runs

SELECT 
    v.name AS vendor,
    cp.name AS context,
    sr.scoring_version,
    sr.score_percentage,
    sr.created_at AS calculation_date,
    RANK() OVER (
        PARTITION BY cp.id, sr.scoring_version 
        ORDER BY sr.score_percentage DESC
    ) AS rank,
    LAG(sr.score_percentage) OVER (
        PARTITION BY v.id, cp.id 
        ORDER BY sr.created_at
    ) AS previous_score,
    sr.score_percentage - LAG(sr.score_percentage) OVER (
        PARTITION BY v.id, cp.id 
        ORDER BY sr.created_at
    ) AS score_change
FROM scored_results sr
JOIN vendors v ON sr.vendor_id = v.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
ORDER BY cp.name, sr.created_at DESC, rank;
```

## Query 8: Industry-Specific Rankings
```sql
-- Dashboard: Industry View
-- Purpose: Rankings filtered by industry with relevant weights

SELECT 
    cp.industry,
    v.name AS vendor,
    v.vendor_type,
    sr.score_percentage,
    sr.detection_active_count,
    RANK() OVER (PARTITION BY cp.industry ORDER BY sr.score_percentage DESC) AS industry_rank,
    STRING_AGG(
        DISTINCT ac.name || ' (weight: ' || COALESCE(cw.weight::TEXT, '1.0') || ')', 
        ', ' ORDER BY ac.name
    ) AS weighted_categories
FROM scored_results sr
JOIN vendors v ON sr.vendor_id = v.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
LEFT JOIN context_weights cw ON cp.id = cw.context_profile_id
LEFT JOIN attack_categories ac ON cw.attack_category_id = ac.id
WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
GROUP BY cp.industry, v.name, v.vendor_type, sr.score_percentage, sr.detection_active_count
ORDER BY cp.industry, industry_rank;
```

## Query 9: MITRE ATT&CK Coverage Map
```sql
-- Dashboard: MITRE Coverage
-- Purpose: Complete MITRE ATT&CK coverage visualization

SELECT 
    v.name AS vendor,
    ac.mitre_tactic,
    a.mitre_technique_id,
    a.name AS technique,
    a.severity,
    dr.detection_state,
    CASE dr.detection_state
        WHEN 'ACTIVE' THEN 3
        WHEN 'DYNAMIC' THEN 2
        WHEN 'NO_EVID' THEN 1
        ELSE 0
    END AS coverage_score
FROM vendors v
CROSS JOIN attacks a
LEFT JOIN detection_results dr ON v.id = dr.vendor_id AND a.id = dr.attack_id
JOIN attack_categories ac ON a.category_id = ac.id
ORDER BY v.name, ac.mitre_tactic, a.mitre_technique_id;
```

## Query 10: Executive Summary
```sql
-- Dashboard: Executive Overview
-- Purpose: High-level metrics for executive reporting

SELECT 
    v.name AS vendor,
    v.vendor_type,
    v.test_date,
    COUNT(DISTINCT dr.attack_id) AS total_attacks_tested,
    COUNT(DISTINCT cp.id) AS contexts_evaluated,
    AVG(sr.score_percentage) AS avg_score_all_contexts,
    MAX(sr.score_percentage) AS best_context_score,
    MIN(sr.score_percentage) AS worst_context_score,
    MAX(sr.score_percentage) - MIN(sr.score_percentage) AS score_variance,
    SUM(sr.detection_active_count) AS total_active_detections,
    ROUND(
        (SUM(sr.detection_active_count)::NUMERIC / 
         NULLIF(SUM(sr.detection_active_count + sr.detection_dynamic_count + sr.detection_no_evid_count), 0) * 100),
        2
    ) AS overall_active_rate
FROM vendors v
LEFT JOIN detection_results dr ON v.id = dr.vendor_id
LEFT JOIN scored_results sr ON v.id = sr.vendor_id
LEFT JOIN context_profiles cp ON sr.context_profile_id = cp.id
WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
GROUP BY v.name, v.vendor_type, v.test_date
ORDER BY avg_score_all_contexts DESC;
```

---

## Metabase Dashboard Suggestions

### Dashboard 1: Executive Overview
- KPIs: Total vendors, contexts, attacks tested
- Chart: Vendor comparison bar chart (avg scores)
- Chart: Detection state distribution pie chart
- Table: Top 5 vendors by average score

### Dashboard 2: Context-Specific Rankings
- Filter: Select context (dropdown)
- Chart: Vendor ranking bar chart for selected context
- Table: Detailed vendor comparison with all metrics
- Chart: Category coverage heatmap

### Dashboard 3: Vendor Deep Dive
- Filter: Select vendor (dropdown)
- Chart: Coverage by category radar chart
- Chart: Detection state distribution
- Table: Attack-level details with gaps highlighted
- Chart: Performance across contexts line chart

### Dashboard 4: Risk Analysis
- Chart: Gap analysis by severity (critical gaps first)
- Chart: Category coverage heatmap (all vendors)
- Table: Top 10 security gaps across all vendors
- Chart: Risk score distribution

### Dashboard 5: Trend Analysis
- Chart: Score evolution over time (line chart)
- Chart: Ranking changes (sankey diagram)
- Table: Score changes table with deltas
- Chart: Detection quality trends

---

## Filter Parameters for Metabase

- **Context**: `{{context_id}}` - Filter by business context
- **Vendor**: `{{vendor_id}}` - Filter by specific vendor
- **Industry**: `{{industry}}` - Filter by industry type
- **Vendor Type**: `{{vendor_type}}` - Filter by EDR/XDR/HYBRID
- **Date Range**: `{{start_date}}` to `{{end_date}}` - Filter by test date
- **Severity**: `{{severity}}` - Filter attacks by severity level
- **Category**: `{{category_id}}` - Filter by attack category

---

## Notes for Metabase Users

1. **Single Source of Truth**: All queries pull from PostgreSQL (Neon)
2. **Read-Only**: Metabase has read-only access - no business logic
3. **Human-Defined**: All rankings use pre-calculated scores from human-approved logic
4. **Explainable**: Every metric can be traced back to source data
5. **No AI**: Zero machine learning or autonomous recommendations in queries
