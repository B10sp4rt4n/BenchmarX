-- ============================================
-- BenchmarX - Sample Benchmark Data
-- ============================================
-- Sample benchmarks and detection results for testing

-- ============================================
-- INSERT SAMPLE BENCHMARKS
-- ============================================

-- Benchmark 1: AVLab Q4 2024
INSERT INTO benchmarks (name, source, report_date, description, imported_by, is_active)
VALUES (
    'AVLab EDR/XDR Q4 2024',
    'AVLab',
    '2024-12-15',
    'Q4 2024 comprehensive EDR/XDR evaluation by AVLab',
    'System',
    false
);

-- Benchmark 2: AVLab Q1 2025 (Active)
INSERT INTO benchmarks (name, source, report_date, description, imported_by, is_active)
VALUES (
    'AVLab EDR/XDR Q1 2025',
    'AVLab',
    '2025-03-01',
    'Q1 2025 comprehensive EDR/XDR evaluation by AVLab - Latest results',
    'System',
    true
);

-- Get benchmark IDs for reference
DO $$
DECLARE
    benchmark_q4_2024 UUID;
    benchmark_q1_2025 UUID;
BEGIN
    -- Get benchmark IDs
    SELECT id INTO benchmark_q4_2024 FROM benchmarks WHERE name = 'AVLab EDR/XDR Q4 2024';
    SELECT id INTO benchmark_q1_2025 FROM benchmarks WHERE name = 'AVLab EDR/XDR Q1 2025';

    -- Update existing detection_results to link to Q4 2024 benchmark
    UPDATE detection_results 
    SET benchmark_id = benchmark_q4_2024
    WHERE benchmark_id IS NULL;

    -- Create some improved results for Q1 2025
    -- This demonstrates vendor improvement over time
    
    -- Example: CrowdStrike improved detection on some attacks
    INSERT INTO detection_results (vendor_id, attack_id, detection_state, benchmark_id)
    SELECT 
        v.id,
        a.id,
        CASE 
            WHEN random() < 0.7 THEN 'ACTIVE'
            WHEN random() < 0.9 THEN 'DYNAMIC'
            ELSE 'NO_EVID'
        END,
        benchmark_q1_2025
    FROM vendors v
    CROSS JOIN attacks a
    WHERE v.name = 'CrowdStrike Falcon'
    ON CONFLICT (vendor_id, attack_id, benchmark_id) DO NOTHING;

    -- Example: Microsoft Defender improvements
    INSERT INTO detection_results (vendor_id, attack_id, detection_state, benchmark_id)
    SELECT 
        v.id,
        a.id,
        CASE 
            WHEN random() < 0.65 THEN 'ACTIVE'
            WHEN random() < 0.88 THEN 'DYNAMIC'
            ELSE 'NO_EVID'
        END,
        benchmark_q1_2025
    FROM vendors v
    CROSS JOIN attacks a
    WHERE v.name = 'Microsoft Defender for Endpoint'
    ON CONFLICT (vendor_id, attack_id, benchmark_id) DO NOTHING;

    -- Example: SentinelOne results
    INSERT INTO detection_results (vendor_id, attack_id, detection_state, benchmark_id)
    SELECT 
        v.id,
        a.id,
        CASE 
            WHEN random() < 0.68 THEN 'ACTIVE'
            WHEN random() < 0.90 THEN 'DYNAMIC'
            ELSE 'NO_EVID'
        END,
        benchmark_q1_2025
    FROM vendors v
    CROSS JOIN attacks a
    WHERE v.name = 'SentinelOne Singularity'
    ON CONFLICT (vendor_id, attack_id, benchmark_id) DO NOTHING;

    -- Example: Palo Alto results
    INSERT INTO detection_results (vendor_id, attack_id, detection_state, benchmark_id)
    SELECT 
        v.id,
        a.id,
        CASE 
            WHEN random() < 0.62 THEN 'ACTIVE'
            WHEN random() < 0.85 THEN 'DYNAMIC'
            ELSE 'NO_EVID'
        END,
        benchmark_q1_2025
    FROM vendors v
    CROSS JOIN attacks a
    WHERE v.name = 'Palo Alto Cortex XDR'
    ON CONFLICT (vendor_id, attack_id, benchmark_id) DO NOTHING;

    -- Example: Trend Micro results
    INSERT INTO detection_results (vendor_id, attack_id, detection_state, benchmark_id)
    SELECT 
        v.id,
        a.id,
        CASE 
            WHEN random() < 0.60 THEN 'ACTIVE'
            WHEN random() < 0.83 THEN 'DYNAMIC'
            ELSE 'NO_EVID'
        END,
        benchmark_q1_2025
    FROM vendors v
    CROSS JOIN attacks a
    WHERE v.name = 'Trend Micro Vision One'
    ON CONFLICT (vendor_id, attack_id, benchmark_id) DO NOTHING;

END $$;

-- ============================================
-- MATERIALIZE SCORES FOR BOTH BENCHMARKS
-- ============================================

-- Calculate scores for Q4 2024
SELECT materialize_scores_for_benchmark(
    (SELECT id FROM benchmarks WHERE name = 'AVLab EDR/XDR Q4 2024')
);

-- Calculate scores for Q1 2025
SELECT materialize_scores_for_benchmark(
    (SELECT id FROM benchmarks WHERE name = 'AVLab EDR/XDR Q1 2025')
);

-- ============================================
-- VERIFY DATA
-- ============================================

-- Show benchmarks
SELECT 
    name,
    source,
    report_date,
    is_active,
    (SELECT COUNT(*) FROM detection_results WHERE benchmark_id = b.id) as detection_count
FROM benchmarks b
ORDER BY report_date;

-- Show score comparison
SELECT 
    b.name AS benchmark,
    v.name AS vendor,
    cp.name AS context,
    sr.score_percentage
FROM scored_results sr
JOIN vendors v ON sr.vendor_id = v.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
JOIN benchmarks b ON sr.benchmark_id = b.id
WHERE cp.name = 'Finance - Large Enterprise'
ORDER BY b.report_date DESC, sr.score_percentage DESC;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE benchmarks IS 'Sample benchmarks demonstrate versioning and evolution tracking';
