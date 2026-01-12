-- ============================================
-- BenchmarX - EDR/XDR Benchmark Platform
-- Database Schema (PostgreSQL / Neon)
-- ============================================
-- Single Source of Truth: All data lives here
-- Human-defined, deterministic, auditable
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- VENDORS (EDR/XDR Solutions)
-- ============================================
CREATE TABLE vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    vendor_type VARCHAR(50) NOT NULL CHECK (vendor_type IN ('EDR', 'XDR', 'HYBRID')),
    description TEXT,
    test_version VARCHAR(100), -- Version tested in the certification
    test_date DATE, -- Date of the test/certification
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vendors_type ON vendors(vendor_type);
CREATE INDEX idx_vendors_test_date ON vendors(test_date);

-- ============================================
-- ATTACK CATEGORIES (MITRE-aligned)
-- ============================================
CREATE TABLE attack_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    mitre_tactic VARCHAR(100), -- e.g., "Initial Access", "Execution"
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ATTACKS (Individual attack techniques)
-- ============================================
CREATE TABLE attacks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES attack_categories(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    mitre_technique_id VARCHAR(50), -- e.g., "T1566.001"
    description TEXT,
    severity VARCHAR(20) DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(category_id, name)
);

CREATE INDEX idx_attacks_category ON attacks(category_id);
CREATE INDEX idx_attacks_severity ON attacks(severity);
CREATE INDEX idx_attacks_mitre_id ON attacks(mitre_technique_id);

-- ============================================
-- DETECTION RESULTS (Core test results)
-- ============================================
-- Detection states based on independent test results (e.g., AVLab)
CREATE TABLE detection_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    attack_id UUID NOT NULL REFERENCES attacks(id) ON DELETE CASCADE,
    detection_state VARCHAR(20) NOT NULL CHECK (detection_state IN ('ACTIVE', 'DYNAMIC', 'NO_EVID')),
    test_run_id VARCHAR(100), -- Reference to the test batch/run
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(vendor_id, attack_id, test_run_id)
);

CREATE INDEX idx_detection_vendor ON detection_results(vendor_id);
CREATE INDEX idx_detection_attack ON detection_results(attack_id);
CREATE INDEX idx_detection_state ON detection_results(detection_state);

-- ============================================
-- CONTEXT PROFILES (Business contexts)
-- ============================================
CREATE TABLE context_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    industry VARCHAR(100), -- e.g., "Finance", "Healthcare", "Manufacturing"
    company_size VARCHAR(50), -- e.g., "Small", "Medium", "Enterprise"
    security_maturity VARCHAR(50), -- e.g., "Basic", "Intermediate", "Advanced"
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_context_industry ON context_profiles(industry);
CREATE INDEX idx_context_size ON context_profiles(company_size);

-- ============================================
-- CONTEXT WEIGHTS (Risk prioritization)
-- ============================================
-- Human-defined weights that determine importance of each attack/category
-- based on business context
CREATE TABLE context_weights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    context_profile_id UUID NOT NULL REFERENCES context_profiles(id) ON DELETE CASCADE,
    attack_category_id UUID REFERENCES attack_categories(id) ON DELETE CASCADE,
    attack_id UUID REFERENCES attacks(id) ON DELETE CASCADE,
    weight DECIMAL(5,2) NOT NULL DEFAULT 1.0 CHECK (weight >= 0 AND weight <= 100),
    rationale TEXT, -- Human explanation for this weight
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (
        (attack_category_id IS NOT NULL AND attack_id IS NULL) OR
        (attack_category_id IS NULL AND attack_id IS NOT NULL)
    ),
    UNIQUE(context_profile_id, attack_category_id),
    UNIQUE(context_profile_id, attack_id)
);

CREATE INDEX idx_weights_profile ON context_weights(context_profile_id);
CREATE INDEX idx_weights_category ON context_weights(attack_category_id);
CREATE INDEX idx_weights_attack ON context_weights(attack_id);

-- ============================================
-- SCORED RESULTS (Materialized outputs)
-- ============================================
-- Human-defined scoring logic results, stored for auditability
CREATE TABLE scored_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    context_profile_id UUID NOT NULL REFERENCES context_profiles(id) ON DELETE CASCADE,
    total_score DECIMAL(10,2) NOT NULL,
    max_possible_score DECIMAL(10,2) NOT NULL,
    score_percentage DECIMAL(5,2) NOT NULL,
    detection_active_count INTEGER NOT NULL DEFAULT 0,
    detection_dynamic_count INTEGER NOT NULL DEFAULT 0,
    detection_no_evid_count INTEGER NOT NULL DEFAULT 0,
    scoring_version VARCHAR(50), -- Version of the scoring logic used
    calculation_metadata JSONB, -- Stores breakdown for auditability
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(vendor_id, context_profile_id, scoring_version, created_at)
);

CREATE INDEX idx_scored_vendor ON scored_results(vendor_id);
CREATE INDEX idx_scored_context ON scored_results(context_profile_id);
CREATE INDEX idx_scored_percentage ON scored_results(score_percentage DESC);
CREATE INDEX idx_scored_version ON scored_results(scoring_version);

-- ============================================
-- SCORING RULES (Human-defined logic)
-- ============================================
-- Stores the explicit, deterministic scoring rules
CREATE TABLE scoring_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version VARCHAR(50) NOT NULL UNIQUE,
    detection_active_points DECIMAL(5,2) NOT NULL DEFAULT 10.0,
    detection_dynamic_points DECIMAL(5,2) NOT NULL DEFAULT 5.0,
    detection_no_evid_points DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    description TEXT,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) -- Human who defined this rule
);

-- Ensure only one active scoring rule at a time
CREATE UNIQUE INDEX idx_scoring_rules_active ON scoring_rules(is_active) WHERE is_active = true;

-- ============================================
-- AUDIT LOG (Change tracking)
-- ============================================
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_by VARCHAR(255), -- User/system identifier
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,
    reason TEXT
);

CREATE INDEX idx_audit_table ON audit_log(table_name);
CREATE INDEX idx_audit_record ON audit_log(record_id);
CREATE INDEX idx_audit_date ON audit_log(changed_at DESC);

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Complete detection results with all context
CREATE OR REPLACE VIEW v_detection_results_complete AS
SELECT 
    dr.id,
    v.name AS vendor_name,
    v.vendor_type,
    ac.name AS category_name,
    ac.mitre_tactic,
    a.name AS attack_name,
    a.mitre_technique_id,
    a.severity,
    dr.detection_state,
    dr.test_run_id,
    dr.notes,
    dr.created_at
FROM detection_results dr
JOIN vendors v ON dr.vendor_id = v.id
JOIN attacks a ON dr.attack_id = a.id
JOIN attack_categories ac ON a.category_id = ac.id;

-- View: Vendor rankings by context
CREATE OR REPLACE VIEW v_vendor_rankings AS
SELECT 
    sr.context_profile_id,
    cp.name AS context_name,
    sr.vendor_id,
    v.name AS vendor_name,
    v.vendor_type,
    sr.total_score,
    sr.max_possible_score,
    sr.score_percentage,
    sr.detection_active_count,
    sr.detection_dynamic_count,
    sr.detection_no_evid_count,
    sr.scoring_version,
    sr.created_at,
    RANK() OVER (PARTITION BY sr.context_profile_id ORDER BY sr.score_percentage DESC) AS rank
FROM scored_results sr
JOIN vendors v ON sr.vendor_id = v.id
JOIN context_profiles cp ON sr.context_profile_id = cp.id
WHERE sr.scoring_version = (SELECT version FROM scoring_rules WHERE is_active = true);

-- ============================================
-- COMMENTS (Documentation in database)
-- ============================================

COMMENT ON TABLE vendors IS 'EDR/XDR solutions tested in independent certifications';
COMMENT ON TABLE attacks IS 'Individual attack techniques aligned with MITRE ATT&CK';
COMMENT ON TABLE detection_results IS 'Raw test results from independent labs (e.g., AVLab)';
COMMENT ON TABLE context_profiles IS 'Business contexts (industry, size, maturity)';
COMMENT ON TABLE context_weights IS 'Human-defined risk prioritization weights per context';
COMMENT ON TABLE scored_results IS 'Materialized scoring outputs for auditability';
COMMENT ON TABLE scoring_rules IS 'Human-defined, deterministic scoring logic';
COMMENT ON TABLE audit_log IS 'Complete change tracking for transparency';

COMMENT ON COLUMN detection_results.detection_state IS 'ACTIVE=Proactively detected, DYNAMIC=Detected after behavior, NO_EVID=Not detected';
COMMENT ON COLUMN context_weights.weight IS 'Multiplier for attack importance (0-100, default 1.0)';
COMMENT ON COLUMN scored_results.calculation_metadata IS 'JSON breakdown of score calculation for full traceability';
