-- ============================================
-- BenchmarX - Scoring Functions
-- ============================================
-- Human-defined, deterministic scoring logic
-- Implemented as PostgreSQL functions
-- ============================================

-- ============================================
-- FUNCTION: Calculate vendor score for a context
-- ============================================
CREATE OR REPLACE FUNCTION calculate_vendor_score(
    p_vendor_id UUID,
    p_context_profile_id UUID,
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

    -- Calculate weighted scores
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
-- FUNCTION: Materialize scores for all vendors and contexts
-- ============================================
CREATE OR REPLACE FUNCTION materialize_all_scores(
    p_scoring_version VARCHAR(50) DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_vendor_record RECORD;
    v_context_record RECORD;
    v_score_record RECORD;
    v_inserted_count INTEGER := 0;
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

    -- Loop through all vendor-context combinations
    FOR v_vendor_record IN SELECT id FROM vendors LOOP
        FOR v_context_record IN SELECT id FROM context_profiles LOOP
            -- Calculate score
            FOR v_score_record IN 
                SELECT * FROM calculate_vendor_score(
                    v_vendor_record.id,
                    v_context_record.id,
                    v_scoring_version
                )
            LOOP
                -- Insert into scored_results
                INSERT INTO scored_results (
                    vendor_id,
                    context_profile_id,
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
                    v_score_record.total_score,
                    v_score_record.max_possible_score,
                    v_score_record.score_percentage,
                    v_score_record.detection_active_count,
                    v_score_record.detection_dynamic_count,
                    v_score_record.detection_no_evid_count,
                    v_scoring_version,
                    v_score_record.calculation_breakdown
                );

                v_inserted_count := v_inserted_count + 1;
            END LOOP;
        END LOOP;
    END LOOP;

    RETURN v_inserted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get vendor ranking for a context
-- ============================================
CREATE OR REPLACE FUNCTION get_vendor_ranking(
    p_context_profile_id UUID,
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
      AND sr.scoring_version = v_scoring_version
    ORDER BY sr.score_percentage DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Get attack category coverage
-- ============================================
CREATE OR REPLACE FUNCTION get_category_coverage(
    p_vendor_id UUID
)
RETURNS TABLE (
    category_name VARCHAR(255),
    total_attacks INTEGER,
    active_detections INTEGER,
    dynamic_detections INTEGER,
    no_evidence INTEGER,
    coverage_percentage DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ac.name AS category_name,
        COUNT(a.id)::INTEGER AS total_attacks,
        SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END)::INTEGER AS active_detections,
        SUM(CASE WHEN dr.detection_state = 'DYNAMIC' THEN 1 ELSE 0 END)::INTEGER AS dynamic_detections,
        SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END)::INTEGER AS no_evidence,
        (SUM(CASE WHEN dr.detection_state IN ('ACTIVE', 'DYNAMIC') THEN 1 ELSE 0 END)::DECIMAL / COUNT(a.id) * 100) AS coverage_percentage
    FROM attack_categories ac
    LEFT JOIN attacks a ON ac.id = a.category_id
    LEFT JOIN detection_results dr ON a.id = dr.attack_id AND dr.vendor_id = p_vendor_id
    GROUP BY ac.name
    ORDER BY coverage_percentage DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON FUNCTION calculate_vendor_score IS 'Core scoring function - calculates weighted score for vendor in specific context';
COMMENT ON FUNCTION materialize_all_scores IS 'Batch function to calculate and store all vendor-context combinations';
COMMENT ON FUNCTION get_vendor_ranking IS 'Returns ranked list of vendors for a specific context';
COMMENT ON FUNCTION get_category_coverage IS 'Returns detection coverage by attack category for a vendor';
