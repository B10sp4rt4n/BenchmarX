-- ============================================
-- BenchmarX - Metabase Queries (Benchmark Versioning)
-- ============================================
-- Additional queries for benchmark comparison and evolution

## Query 11: Benchmark Rankings Comparison
```sql
-- Dashboard: Benchmark Comparison
-- Purpose: Compare vendor rankings across different benchmarks

SELECT 
    b.name AS benchmark,
    b.report_date,
    cp.name AS context,
    v.name AS vendor,
    sr.score_percentage,
    RANK() OVER (PARTITION BY b.id, cp.id ORDER BY sr.score_percentage DESC) AS rank,
    sr.detection_active_count AS active,
    sr.detection_dynamic_count AS dynamic,
    sr.detection_no_evid_count AS no_evidence
FROM scored_results sr
JOIN vendors v ON sr.vendor_id = v.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
JOIN benchmarks b ON sr.benchmark_id = b.id
WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
  AND cp.id = {{context_id}}
ORDER BY b.report_date DESC, rank;
```

## Query 12: Vendor Evolution Over Time
```sql
-- Dashboard: Vendor Trends
-- Purpose: Track vendor score evolution across benchmarks

SELECT 
    v.name AS vendor,
    b.name AS benchmark,
    b.report_date,
    sr.score_percentage,
    sr.detection_active_count,
    LAG(sr.score_percentage) OVER (
        PARTITION BY v.id, cp.id 
        ORDER BY b.report_date
    ) AS previous_score,
    sr.score_percentage - LAG(sr.score_percentage) OVER (
        PARTITION BY v.id, cp.id 
        ORDER BY b.report_date
    ) AS score_change
FROM scored_results sr
JOIN vendors v ON sr.vendor_id = v.id
JOIN benchmarks b ON sr.benchmark_id = b.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
WHERE v.id = {{vendor_id}}
  AND cp.id = {{context_id}}
ORDER BY b.report_date;
```

## Query 13: Benchmark Coverage Statistics
```sql
-- Dashboard: Benchmark Overview
-- Purpose: Summary statistics for each benchmark

SELECT 
    b.name AS benchmark,
    b.source,
    b.report_date,
    COUNT(DISTINCT dr.vendor_id) AS vendors_tested,
    COUNT(DISTINCT dr.attack_id) AS attacks_covered,
    COUNT(*) AS total_detections,
    SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END) AS active_detections,
    SUM(CASE WHEN dr.detection_state = 'DYNAMIC' THEN 1 ELSE 0 END) AS dynamic_detections,
    SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END) AS no_evidence,
    ROUND(
        (SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END)::NUMERIC / 
         COUNT(*) * 100), 2
    ) AS active_percentage
FROM benchmarks b
LEFT JOIN detection_results dr ON b.id = dr.benchmark_id
GROUP BY b.id, b.name, b.source, b.report_date
ORDER BY b.report_date DESC;
```

## Query 14: Rank Movement Visualization
```sql
-- Dashboard: Competitive Landscape
-- Purpose: Show how vendor ranks change between benchmarks

WITH ranked_results AS (
    SELECT 
        b.name AS benchmark,
        b.report_date,
        cp.name AS context,
        v.name AS vendor,
        sr.score_percentage,
        RANK() OVER (PARTITION BY b.id, cp.id ORDER BY sr.score_percentage DESC) AS rank
    FROM scored_results sr
    JOIN vendors v ON sr.vendor_id = v.id
    JOIN context_profiles cp ON sr.context_profile_id = cp.id
    JOIN benchmarks b ON sr.benchmark_id = b.id
    WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
)
SELECT 
    vendor,
    benchmark,
    report_date,
    context,
    rank,
    LAG(rank) OVER (PARTITION BY vendor, context ORDER BY report_date) AS previous_rank,
    rank - LAG(rank) OVER (PARTITION BY vendor, context ORDER BY report_date) AS rank_change
FROM ranked_results
WHERE context = {{context_name}}
ORDER BY report_date DESC, rank;
```

## Query 15: Attack Coverage Evolution
```sql
-- Dashboard: Coverage Trends
-- Purpose: Track how attack coverage changes across benchmarks

SELECT 
    ac.name AS category,
    b.name AS benchmark,
    b.report_date,
    v.name AS vendor,
    COUNT(a.id) AS total_attacks,
    SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END) AS active_detections,
    ROUND(
        (SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END)::NUMERIC / 
         COUNT(a.id) * 100), 2
    ) AS coverage_percentage
FROM benchmarks b
CROSS JOIN vendors v
CROSS JOIN attack_categories ac
LEFT JOIN attacks a ON ac.id = a.category_id
LEFT JOIN detection_results dr ON a.id = dr.attack_id 
    AND dr.vendor_id = v.id 
    AND dr.benchmark_id = b.id
WHERE v.id = {{vendor_id}}
GROUP BY ac.name, b.name, b.report_date, v.name
ORDER BY b.report_date DESC, coverage_percentage DESC;
```

## Query 16: Multi-Benchmark Heatmap
```sql
-- Dashboard: Evolution Heatmap
-- Purpose: Heatmap showing coverage evolution across benchmarks

SELECT 
    v.name AS vendor,
    ac.name AS category,
    b.name AS benchmark,
    b.report_date,
    ROUND(
        (SUM(CASE WHEN dr.detection_state IN ('ACTIVE', 'DYNAMIC') THEN 1 ELSE 0 END)::NUMERIC / 
         COUNT(a.id) * 100), 2
    ) AS coverage_percentage,
    SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END) AS gaps
FROM benchmarks b
CROSS JOIN vendors v
CROSS JOIN attack_categories ac
LEFT JOIN attacks a ON ac.id = a.category_id
LEFT JOIN detection_results dr ON a.id = dr.attack_id 
    AND dr.vendor_id = v.id 
    AND dr.benchmark_id = b.id
GROUP BY v.name, ac.name, b.name, b.report_date
ORDER BY v.name, b.report_date DESC, coverage_percentage;
```

## Query 17: Top Performers by Benchmark
```sql
-- Dashboard: Winners Circle
-- Purpose: Top 3 vendors per benchmark and context

WITH ranked_vendors AS (
    SELECT 
        b.name AS benchmark,
        b.report_date,
        cp.name AS context,
        v.name AS vendor,
        v.vendor_type,
        sr.score_percentage,
        RANK() OVER (PARTITION BY b.id, cp.id ORDER BY sr.score_percentage DESC) AS rank
    FROM scored_results sr
    JOIN vendors v ON sr.vendor_id = v.id
    JOIN context_profiles cp ON sr.context_profile_id = cp.id
    JOIN benchmarks b ON sr.benchmark_id = b.id
    WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
)
SELECT *
FROM ranked_vendors
WHERE rank <= 3
ORDER BY report_date DESC, context, rank;
```

## Query 18: Benchmark Import Audit
```sql
-- Dashboard: Data Quality
-- Purpose: Track when and by whom benchmarks were imported

SELECT 
    b.name AS benchmark,
    b.source,
    b.report_date,
    b.imported_at,
    b.imported_by,
    b.is_active,
    COUNT(DISTINCT dr.vendor_id) AS vendors_imported,
    COUNT(DISTINCT dr.attack_id) AS attacks_imported,
    COUNT(*) AS detection_records,
    COUNT(DISTINCT sr.context_profile_id) AS contexts_scored
FROM benchmarks b
LEFT JOIN detection_results dr ON b.id = dr.benchmark_id
LEFT JOIN scored_results sr ON b.id = sr.benchmark_id
GROUP BY b.id, b.name, b.source, b.report_date, b.imported_at, b.imported_by, b.is_active
ORDER BY b.imported_at DESC;
```

## Query 19: Score Distribution by Benchmark
```sql
-- Dashboard: Statistical Analysis
-- Purpose: Score distribution statistics per benchmark

SELECT 
    b.name AS benchmark,
    cp.name AS context,
    COUNT(DISTINCT sr.vendor_id) AS vendor_count,
    AVG(sr.score_percentage) AS avg_score,
    STDDEV(sr.score_percentage) AS std_dev,
    MIN(sr.score_percentage) AS min_score,
    MAX(sr.score_percentage) AS max_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sr.score_percentage) AS median_score
FROM scored_results sr
JOIN benchmarks b ON sr.benchmark_id = b.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)
GROUP BY b.name, cp.name
ORDER BY b.name, cp.name;
```

## Query 20: Active Benchmark Summary
```sql
-- Dashboard: Current State
-- Purpose: Quick overview of the active benchmark

SELECT 
    b.name AS benchmark,
    b.source,
    b.report_date,
    b.imported_at,
    COUNT(DISTINCT dr.vendor_id) AS vendors,
    COUNT(DISTINCT dr.attack_id) AS attacks,
    COUNT(DISTINCT cp.id) AS contexts_calculated,
    COUNT(DISTINCT sr.id) AS total_scores,
    AVG(sr.score_percentage) AS avg_score_all_contexts
FROM benchmarks b
LEFT JOIN detection_results dr ON b.id = dr.benchmark_id
LEFT JOIN scored_results sr ON b.id = sr.benchmark_id
LEFT JOIN context_profiles cp ON sr.context_profile_id = cp.id
WHERE b.is_active = true
GROUP BY b.id, b.name, b.source, b.report_date, b.imported_at;
```

---

## Filter Parameters (Additional)

- **Benchmark**: `{{benchmark_id}}` - Filter by specific benchmark
- **Benchmark Date Range**: `{{start_date}}` to `{{end_date}}` - Filter benchmarks by date
- **Active Only**: `{{active_only}}` - Show only active benchmark

---

## Dashboard Suggestions (Updated)

### Dashboard 6: Benchmark Evolution
- Chart: Score evolution timeline (line chart)
- Chart: Rank movement Sankey diagram
- Table: Benchmark comparison matrix
- Filter: Select vendor and context

### Dashboard 7: Competitive Landscape
- Chart: Rank changes heatmap
- Chart: Market share by score tier
- Table: Head-to-head comparisons
- Filter: Select benchmarks to compare

### Dashboard 8: Data Quality Monitor
- Table: Import audit log
- Chart: Coverage completeness by benchmark
- KPIs: Data freshness, completeness
- Alerts: Missing data or anomalies

---

## Notes for Benchmark Versioning

1. **Historical Data**: All queries preserve historical benchmark data
2. **Comparison**: Easy to compare vendor performance across time
3. **Audit Trail**: Complete tracking of who imported what and when
4. **Active Benchmark**: Most queries filter by active benchmark by default
5. **Traceability**: Every score is linked to a specific benchmark version
