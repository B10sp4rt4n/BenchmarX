-- ============================================-- ============================================






































































































































































































































































FROM benchmarks WHERE is_active = true;SELECT 'Active benchmark' AS status, name, report_date -- Show active benchmarkFROM scored_results WHERE benchmark_id IS NOT NULL;SELECT 'Scored results updated' AS status, COUNT(*) AS scores_with_benchmark -- Verify scored_results updatedFROM detection_results WHERE benchmark_id IS NOT NULL;SELECT 'Detection results updated' AS status, COUNT(*) AS results_with_benchmark -- Verify detection_results updatedSELECT 'Benchmarks table created' AS status, COUNT(*) AS benchmark_count FROM benchmarks;-- Verify benchmarks table-- ============================================-- VALIDATION QUERIES-- ============================================);    )        'migration_date', CURRENT_TIMESTAMP        'views_created', ARRAY['v_benchmark_comparison'],        'views_modified', ARRAY['v_detection_results_complete', 'v_vendor_rankings'],        'tables_modified', ARRAY['benchmarks', 'detection_results', 'scored_results'],    jsonb_build_object(    'Added benchmark versioning support',    'System Migration',    'UPDATE',    uuid_generate_v4(),    'schema',VALUES (INSERT INTO audit_log (table_name, record_id, action, changed_by, reason, new_values)-- ============================================-- AUDIT LOG ENTRY-- ============================================COMMENT ON FUNCTION set_active_benchmark IS 'Set the active benchmark (only one can be active at a time)';$$ LANGUAGE plpgsql;END;    RETURN FOUND;        WHERE id = p_benchmark_id;    SET is_active = true     UPDATE benchmarks     -- Activate the specified benchmark        UPDATE benchmarks SET is_active = false;    -- Deactivate all benchmarksBEGINRETURNS BOOLEAN AS $$CREATE OR REPLACE FUNCTION set_active_benchmark(p_benchmark_id UUID)-- Function to set active benchmarkCOMMENT ON FUNCTION get_active_benchmark IS 'Returns the UUID of the currently active benchmark';$$ LANGUAGE plpgsql;END;    RETURN (SELECT id FROM benchmarks WHERE is_active = true LIMIT 1);BEGINRETURNS UUID AS $$CREATE OR REPLACE FUNCTION get_active_benchmark()-- Function to get active benchmark-- ============================================-- HELPER FUNCTIONS-- ============================================COMMENT ON VIEW v_benchmark_comparison IS 'Compare vendor performance across different benchmarks over time';ORDER BY b.report_date DESC, cp.name, sr.score_percentage DESC;WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true)JOIN benchmarks b ON sr.benchmark_id = b.idJOIN context_profiles cp ON sr.context_profile_id = cp.idJOIN vendors v ON sr.vendor_id = v.idFROM scored_results sr    ) AS rank_in_benchmark        ORDER BY sr.score_percentage DESC        PARTITION BY cp.id, b.id     RANK() OVER (    ) AS score_change,        ORDER BY b.report_date        PARTITION BY v.id, cp.id     sr.score_percentage - LAG(sr.score_percentage) OVER (    ) AS previous_score,        ORDER BY b.report_date        PARTITION BY v.id, cp.id     LAG(sr.score_percentage) OVER (    sr.detection_no_evid_count,    sr.detection_dynamic_count,    sr.detection_active_count,    sr.total_score,    sr.score_percentage,    b.report_date AS benchmark_date,    b.name AS benchmark_name,    cp.name AS context_name,    v.vendor_type,    v.name AS vendor_name,SELECT CREATE OR REPLACE VIEW v_benchmark_comparison AS-- ============================================-- NEW VIEW: Benchmark Comparison-- ============================================WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true);JOIN benchmarks b ON sr.benchmark_id = b.idJOIN context_profiles cp ON sr.context_profile_id = cp.idJOIN vendors v ON sr.vendor_id = v.idFROM scored_results sr    ) AS rank        ORDER BY sr.score_percentage DESC        PARTITION BY sr.context_profile_id, sr.benchmark_id     RANK() OVER (    b.report_date AS benchmark_date,    b.name AS benchmark_name,    sr.benchmark_id,    sr.created_at,    sr.scoring_version,    sr.detection_no_evid_count,    sr.detection_dynamic_count,    sr.detection_active_count,    sr.score_percentage,    sr.max_possible_score,    sr.total_score,    v.vendor_type,    v.name AS vendor_name,    sr.vendor_id,    cp.name AS context_name,    sr.context_profile_id,SELECT CREATE OR REPLACE VIEW v_vendor_rankings ASDROP VIEW IF EXISTS v_vendor_rankings;-- Drop and recreate v_vendor_rankings to include benchmark infoJOIN benchmarks b ON dr.benchmark_id = b.id;JOIN attack_categories ac ON a.category_id = ac.idJOIN attacks a ON dr.attack_id = a.idJOIN vendors v ON dr.vendor_id = v.idFROM detection_results dr    b.report_date AS benchmark_date    b.source AS benchmark_source,    b.name AS benchmark_name,    b.id AS benchmark_id,    dr.created_at,    dr.notes,    dr.test_run_id,    dr.detection_state,    a.severity,    a.mitre_technique_id,    a.name AS attack_name,    ac.mitre_tactic,    ac.name AS category_name,    v.vendor_type,    v.name AS vendor_name,    dr.id,SELECT CREATE OR REPLACE VIEW v_detection_results_complete ASDROP VIEW IF EXISTS v_detection_results_complete;-- Drop and recreate v_detection_results_complete to include benchmark info-- ============================================-- VIEWS - Update to be benchmark-aware-- ============================================UNIQUE(vendor_id, context_profile_id, benchmark_id, scoring_version);ADD CONSTRAINT scored_results_unique_per_benchmarkALTER TABLE scored_resultsDROP CONSTRAINT IF EXISTS scored_results_vendor_id_context_profile_id_scoring_version_;ALTER TABLE scored_results-- Update unique constraint to include benchmark_idCREATE INDEX idx_scored_benchmark ON scored_results(benchmark_id);-- Create index for performanceALTER COLUMN benchmark_id SET NOT NULL;ALTER TABLE scored_results-- Make benchmark_id required going forwardWHERE benchmark_id IS NULL;SET benchmark_id = (SELECT id FROM benchmarks WHERE name = 'Initial Seed Data')UPDATE scored_results-- Update existing scored_results to reference the default benchmarkADD COLUMN benchmark_id UUID REFERENCES benchmarks(id) ON DELETE CASCADE;ALTER TABLE scored_results-- Add benchmark_id to track which benchmark each score came from-- ============================================-- MODIFY SCORED_RESULTS-- ============================================UNIQUE(vendor_id, attack_id, benchmark_id);ADD CONSTRAINT detection_results_unique_per_benchmark ALTER TABLE detection_resultsDROP CONSTRAINT IF EXISTS detection_results_vendor_id_attack_id_test_run_id_key;ALTER TABLE detection_results-- Update unique constraint to include benchmark_idALTER COLUMN benchmark_id SET NOT NULL;ALTER TABLE detection_results-- Make benchmark_id required going forwardWHERE benchmark_id IS NULL;SET benchmark_id = (SELECT id FROM benchmarks WHERE name = 'Initial Seed Data')UPDATE detection_results-- Update existing detection_results to reference the default benchmark);    true    'System Migration',    'Default benchmark created during schema migration for existing detection results',    CURRENT_DATE,    'System',    'Initial Seed Data',VALUES (INSERT INTO benchmarks (name, source, report_date, description, imported_by, is_active)-- First, create a default benchmark for existing data-- Update existing detection_results to reference a default benchmarkCREATE INDEX idx_detection_benchmark ON detection_results(benchmark_id);-- Create index for performanceADD COLUMN benchmark_id UUID REFERENCES benchmarks(id) ON DELETE CASCADE;ALTER TABLE detection_results-- Add benchmark_id to track which benchmark each result came from-- ============================================-- MODIFY DETECTION_RESULTS-- ============================================COMMENT ON COLUMN benchmarks.is_active IS 'Only one benchmark should be active at a time for default calculations';COMMENT ON TABLE benchmarks IS 'Versioned benchmark reports from independent test labs';CREATE INDEX idx_benchmarks_active ON benchmarks(is_active) WHERE is_active = true;CREATE INDEX idx_benchmarks_source ON benchmarks(source);CREATE INDEX idx_benchmarks_date ON benchmarks(report_date DESC););    UNIQUE(name, report_date)    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    is_active BOOLEAN DEFAULT true, -- Whether to use in default calculations    imported_by VARCHAR(255), -- Human who imported the benchmark    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    description TEXT,    report_date DATE NOT NULL,    source VARCHAR(100) NOT NULL, -- e.g., "AVLab", "AV-TEST", "SE Labs"    name VARCHAR(255) NOT NULL,    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),CREATE TABLE benchmarks (-- ============================================-- BENCHMARKS TABLE (Source of Truth for Tests)-- ============================================-- ============================================-- Allows comparison of results over time-- Extends schema to support benchmark versioning-- ============================================-- BenchmarX - Benchmark Versioning Migration-- BenchmarX - Benchmark Versioning Migration
-- ============================================
-- Adds benchmark versioning capability to track
-- different test reports over time
-- ============================================

-- ============================================
-- BENCHMARKS TABLE
-- ============================================
-- Stores metadata about each benchmark report
CREATE TABLE benchmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    source VARCHAR(100), -- e.g., "AVLab", "AV-Comparatives", "MITRE ATT&CK Eval"
    report_date DATE NOT NULL,
    description TEXT,
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    imported_by VARCHAR(255), -- Human who imported this benchmark
    is_active BOOLEAN DEFAULT true, -- Currently active benchmark for calculations
    metadata JSONB, -- Additional metadata (e.g., methodology notes, coverage scope)
    UNIQUE(name, source, report_date)
);

CREATE INDEX idx_benchmarks_date ON benchmarks(report_date DESC);
CREATE INDEX idx_benchmarks_source ON benchmarks(source);
CREATE INDEX idx_benchmarks_active ON benchmarks(is_active) WHERE is_active = true;

-- ============================================
-- ADD BENCHMARK_ID TO DETECTION_RESULTS
-- ============================================
-- Link each detection result to its benchmark
ALTER TABLE detection_results
ADD COLUMN benchmark_id UUID REFERENCES benchmarks(id) ON DELETE CASCADE;

-- Update unique constraint to include benchmark_id
ALTER TABLE detection_results
DROP CONSTRAINT IF EXISTS detection_results_vendor_id_attack_id_test_run_id_key;

ALTER TABLE detection_results
ADD CONSTRAINT detection_results_unique_per_benchmark
UNIQUE(vendor_id, attack_id, benchmark_id);

CREATE INDEX idx_detection_benchmark ON detection_results(benchmark_id);

-- ============================================
-- ADD BENCHMARK_ID TO SCORED_RESULTS
-- ============================================
-- Link each scored result to its benchmark
ALTER TABLE scored_results
ADD COLUMN benchmark_id UUID REFERENCES benchmarks(id) ON DELETE CASCADE;

-- Update unique constraint to include benchmark_id
ALTER TABLE scored_results
DROP CONSTRAINT IF EXISTS scored_results_vendor_id_context_profile_id_scoring_vers_key;

ALTER TABLE scored_results
ADD CONSTRAINT scored_results_unique_per_benchmark
UNIQUE(vendor_id, context_profile_id, benchmark_id, scoring_version);

CREATE INDEX idx_scored_benchmark ON scored_results(benchmark_id);

-- ============================================
-- UPDATED CALCULATE_VENDOR_SCORE FUNCTION
-- ============================================
-- Now supports benchmark-specific calculations
DROP FUNCTION IF EXISTS calculate_vendor_score(UUID, UUID, VARCHAR);

CREATE OR REPLACE FUNCTION calculate_vendor_score(
    p_vendor_id UUID,
    p_context_profile_id UUID,
    p_benchmark_id UUID,
    p_scoring_version VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    total_score DECIMAL(10,2),
    max_possible_score DECIMAL(10,2),
    score_percentage DECIMAL(5,2),
    detection_active_count INTEGER,
    detection_dynamic_count INTEGER,
    detection_no_evid_count INTEGER,
    calculation_breakdown JSONB
) AS $$
DECLARE
    v_scoring_version VARCHAR(50);
    v_active_points DECIMAL(5,2);
    v_dynamic_points DECIMAL(5,2);
    v_no_evid_points DECIMAL(5,2);
    v_total_score DECIMAL(10,2);
    v_max_score DECIMAL(10,2);
    v_active_count INTEGER;
    v_dynamic_count INTEGER;
    v_no_evid_count INTEGER;
    v_breakdown JSONB;
BEGIN
    -- Get scoring rule version
    IF p_scoring_version IS NULL THEN
        SELECT version, detection_active_points, detection_dynamic_points, detection_no_evid_points
        INTO v_scoring_version, v_active_points, v_dynamic_points, v_no_evid_points
        FROM scoring_rules
        WHERE is_active = true
        LIMIT 1;
    ELSE
        SELECT version, detection_active_points, detection_dynamic_points, detection_no_evid_points
        INTO v_scoring_version, v_active_points, v_dynamic_points, v_no_evid_points
        FROM scoring_rules
        WHERE version = p_scoring_version
        LIMIT 1;
    END IF;

    -- Calculate weighted scores for specific benchmark
    WITH weighted_detections AS (
        SELECT 
            dr.detection_state,
            a.id AS attack_id,
            a.category_id,
            COALESCE(
                (SELECT weight FROM context_weights 
                 WHERE context_profile_id = p_context_profile_id 
                 AND attack_id = a.id),
                (SELECT weight FROM context_weights 
                 WHERE context_profile_id = p_context_profile_id 
                 AND attack_category_id = a.category_id),
                1.0
            ) AS weight,
            CASE 
                WHEN dr.detection_state = 'ACTIVE' THEN v_active_points
                WHEN dr.detection_state = 'DYNAMIC' THEN v_dynamic_points
                ELSE v_no_evid_points
            END AS base_points
        FROM detection_results dr
        JOIN attacks a ON dr.attack_id = a.id
        WHERE dr.vendor_id = p_vendor_id
          AND dr.benchmark_id = p_benchmark_id
    ),
    score_calc AS (
        SELECT 
            SUM(base_points * weight) AS total,
            SUM(v_active_points * weight) AS max_possible,
            SUM(CASE WHEN detection_state = 'ACTIVE' THEN 1 ELSE 0 END) AS active_cnt,
            SUM(CASE WHEN detection_state = 'DYNAMIC' THEN 1 ELSE 0 END) AS dynamic_cnt,
            SUM(CASE WHEN detection_state = 'NO_EVID' THEN 1 ELSE 0 END) AS no_evid_cnt,
            jsonb_agg(
                jsonb_build_object(
                    'attack_id', attack_id,
                    'detection_state', detection_state,
                    'weight', weight,
                    'base_points', base_points,
                    'weighted_points', base_points * weight
                )
            ) AS breakdown
        FROM weighted_detections
    )
    SELECT 
        sc.total,
        sc.max_possible,
        CASE WHEN sc.max_possible > 0 THEN (sc.total / sc.max_possible * 100) ELSE 0 END,
        sc.active_cnt,
        sc.dynamic_cnt,
        sc.no_evid_cnt,
        sc.breakdown
    INTO 
        v_total_score,
        v_max_score,
        score_percentage,
        v_active_count,
        v_dynamic_count,
        v_no_evid_count,
        v_breakdown
    FROM score_calc sc;

    -- Return results
    total_score := v_total_score;
    max_possible_score := v_max_score;
    detection_active_count := v_active_count;
    detection_dynamic_count := v_dynamic_count;
    detection_no_evid_count := v_no_evid_count;
    calculation_breakdown := v_breakdown;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- MATERIALIZE SCORES FOR BENCHMARK
-- ============================================
-- Human-triggered function to recalculate scores for a specific benchmark
CREATE OR REPLACE FUNCTION materialize_scores_for_benchmark(
    p_benchmark_id UUID,
    p_scoring_version VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    vendor_id UUID,
    context_id UUID,
    scores_calculated BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_vendor_record RECORD;
    v_context_record RECORD;
    v_score_record RECORD;
    v_scoring_version VARCHAR(50);
    v_error_msg TEXT;
BEGIN
    -- Get scoring version
    IF p_scoring_version IS NULL THEN
        SELECT version INTO v_scoring_version
        FROM scoring_rules
        WHERE is_active = true
        LIMIT 1;
    ELSE
        v_scoring_version := p_scoring_version;
    END IF;

    -- Verify benchmark exists
    IF NOT EXISTS (SELECT 1 FROM benchmarks WHERE id = p_benchmark_id) THEN
        RAISE EXCEPTION 'Benchmark % does not exist', p_benchmark_id;
    END IF;

    -- Loop through all vendor-context combinations
    FOR v_vendor_record IN 
        SELECT DISTINCT v.id 
        FROM vendors v
        JOIN detection_results dr ON v.id = dr.vendor_id
        WHERE dr.benchmark_id = p_benchmark_id
    LOOP
        FOR v_context_record IN SELECT id FROM context_profiles LOOP
            BEGIN
                -- Calculate score
                FOR v_score_record IN 
                    SELECT * FROM calculate_vendor_score(
                        v_vendor_record.id,
                        v_context_record.id,
                        p_benchmark_id,
                        v_scoring_version
                    )
                LOOP
                    -- Insert or update scored_results
                    INSERT INTO scored_results (
                        vendor_id,
                        context_profile_id,
                        benchmark_id,
                        total_score,
                        max_possible_score,
                        score_percentage,
                        detection_active_count,
                        detection_dynamic_count,
                        detection_no_evid_count,
                        scoring_version,
                        calculation_metadata
                    ) VALUES (
                        v_vendor_record.id,
                        v_context_record.id,
                        p_benchmark_id,
                        v_score_record.total_score,
                        v_score_record.max_possible_score,
                        v_score_record.score_percentage,
                        v_score_record.detection_active_count,
                        v_score_record.detection_dynamic_count,
                        v_score_record.detection_no_evid_count,
                        v_scoring_version,
                        v_score_record.calculation_breakdown
                    )
                    ON CONFLICT (vendor_id, context_profile_id, benchmark_id, scoring_version)
                    DO UPDATE SET
                        total_score = EXCLUDED.total_score,
                        max_possible_score = EXCLUDED.max_possible_score,
                        score_percentage = EXCLUDED.score_percentage,
                        detection_active_count = EXCLUDED.detection_active_count,
                        detection_dynamic_count = EXCLUDED.detection_dynamic_count,
                        detection_no_evid_count = EXCLUDED.detection_no_evid_count,
                        calculation_metadata = EXCLUDED.calculation_metadata,
                        created_at = CURRENT_TIMESTAMP;

                    vendor_id := v_vendor_record.id;
                    context_id := v_context_record.id;
                    scores_calculated := true;
                    error_message := NULL;
                    RETURN NEXT;
                END LOOP;
            EXCEPTION
                WHEN OTHERS THEN
                    v_error_msg := SQLERRM;
                    vendor_id := v_vendor_record.id;
                    context_id := v_context_record.id;
                    scores_calculated := false;
                    error_message := v_error_msg;
                    RETURN NEXT;
            END;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- GET VENDOR RANKING FOR BENCHMARK
-- ============================================
CREATE OR REPLACE FUNCTION get_vendor_ranking_for_benchmark(
    p_context_profile_id UUID,
    p_benchmark_id UUID,
    p_scoring_version VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    rank INTEGER,
    vendor_name VARCHAR(255),
    vendor_type VARCHAR(50),
    score_percentage DECIMAL(5,2),
    total_score DECIMAL(10,2),
    active_count INTEGER,
    dynamic_count INTEGER,
    no_evid_count INTEGER
) AS $$
DECLARE
    v_scoring_version VARCHAR(50);
BEGIN
    -- Get scoring version
    IF p_scoring_version IS NULL THEN
        SELECT version INTO v_scoring_version
        FROM scoring_rules
        WHERE is_active = true
        LIMIT 1;
    ELSE
        v_scoring_version := p_scoring_version;
    END IF;

    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY sr.score_percentage DESC)::INTEGER AS rank,
        v.name AS vendor_name,
        v.vendor_type,
        sr.score_percentage,
        sr.total_score,
        sr.detection_active_count AS active_count,
        sr.detection_dynamic_count AS dynamic_count,
        sr.detection_no_evid_count AS no_evid_count
    FROM scored_results sr
    JOIN vendors v ON sr.vendor_id = v.id
    WHERE sr.context_profile_id = p_context_profile_id
      AND sr.benchmark_id = p_benchmark_id
      AND sr.scoring_version = v_scoring_version
    ORDER BY sr.score_percentage DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMPARE BENCHMARKS
-- ============================================
-- Compare vendor performance across different benchmarks
CREATE OR REPLACE FUNCTION compare_benchmarks(
    p_vendor_id UUID,
    p_context_profile_id UUID,
    p_benchmark_ids UUID[]
)
RETURNS TABLE (
    benchmark_name VARCHAR(255),
    benchmark_date DATE,
    score_percentage DECIMAL(5,2),
    total_score DECIMAL(10,2),
    rank INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.name AS benchmark_name,
        b.report_date AS benchmark_date,
        sr.score_percentage,
        sr.total_score,
        (
            SELECT COUNT(*) + 1
            FROM scored_results sr2
            WHERE sr2.context_profile_id = p_context_profile_id
              AND sr2.benchmark_id = sr.benchmark_id
              AND sr2.score_percentage > sr.score_percentage
        )::INTEGER AS rank
    FROM scored_results sr
    JOIN benchmarks b ON sr.benchmark_id = b.id
    WHERE sr.vendor_id = p_vendor_id
      AND sr.context_profile_id = p_context_profile_id
      AND sr.benchmark_id = ANY(p_benchmark_ids)
    ORDER BY b.report_date DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE benchmarks IS 'Tracks different benchmark reports over time (e.g., AVLab 2024, AVLab 2025)';
COMMENT ON COLUMN detection_results.benchmark_id IS 'Links detection result to specific benchmark report';
COMMENT ON COLUMN scored_results.benchmark_id IS 'Links score to specific benchmark for historical comparison';
COMMENT ON FUNCTION materialize_scores_for_benchmark IS 'Human-triggered: Recalculate all scores for a specific benchmark';
COMMENT ON FUNCTION get_vendor_ranking_for_benchmark IS 'Get vendor rankings for a specific benchmark and context';
COMMENT ON FUNCTION compare_benchmarks IS 'Compare vendor performance across multiple benchmarks';
