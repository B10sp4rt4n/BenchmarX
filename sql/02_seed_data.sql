-- ============================================
-- BenchmarX - Seed Data
-- ============================================
-- Initial data for demonstration and testing
-- ============================================

-- ============================================
-- SCORING RULES (Default)
-- ============================================
INSERT INTO scoring_rules (version, detection_active_points, detection_dynamic_points, detection_no_evid_points, description, is_active, created_by)
VALUES 
    ('v1.0', 10.0, 5.0, 0.0, 'Default scoring: ACTIVE=10pts, DYNAMIC=5pts, NO_EVID=0pts', true, 'System');

-- ============================================
-- ATTACK CATEGORIES
-- ============================================
INSERT INTO attack_categories (name, mitre_tactic, description)
VALUES 
    ('Initial Access', 'TA0001', 'Techniques used to gain initial foothold'),
    ('Execution', 'TA0002', 'Techniques that result in execution of adversary code'),
    ('Persistence', 'TA0003', 'Techniques to maintain access across restarts'),
    ('Privilege Escalation', 'TA0004', 'Techniques to gain higher-level permissions'),
    ('Defense Evasion', 'TA0005', 'Techniques to avoid detection'),
    ('Credential Access', 'TA0006', 'Techniques to steal account credentials'),
    ('Discovery', 'TA0007', 'Techniques to gain knowledge about the system'),
    ('Lateral Movement', 'TA0008', 'Techniques to move through the network'),
    ('Collection', 'TA0009', 'Techniques to gather information of interest'),
    ('Command and Control', 'TA0011', 'Techniques to communicate with compromised systems'),
    ('Exfiltration', 'TA0010', 'Techniques to steal data from the network'),
    ('Impact', 'TA0040', 'Techniques to manipulate, interrupt, or destroy systems');

-- ============================================
-- SAMPLE ATTACKS (Aligned with common EDR tests)
-- ============================================
DO $$
DECLARE
    cat_initial_access UUID;
    cat_execution UUID;
    cat_persistence UUID;
    cat_privilege_esc UUID;
    cat_defense_evasion UUID;
    cat_credential_access UUID;
    cat_lateral_movement UUID;
    cat_impact UUID;
BEGIN
    SELECT id INTO cat_initial_access FROM attack_categories WHERE name = 'Initial Access';
    SELECT id INTO cat_execution FROM attack_categories WHERE name = 'Execution';
    SELECT id INTO cat_persistence FROM attack_categories WHERE name = 'Persistence';
    SELECT id INTO cat_privilege_esc FROM attack_categories WHERE name = 'Privilege Escalation';
    SELECT id INTO cat_defense_evasion FROM attack_categories WHERE name = 'Defense Evasion';
    SELECT id INTO cat_credential_access FROM attack_categories WHERE name = 'Credential Access';
    SELECT id INTO cat_lateral_movement FROM attack_categories WHERE name = 'Lateral Movement';
    SELECT id INTO cat_impact FROM attack_categories WHERE name = 'Impact';

    -- Initial Access attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_initial_access, 'Phishing Email with Malicious Attachment', 'T1566.001', 'HIGH', 'Email with weaponized document'),
        (cat_initial_access, 'Drive-by Compromise', 'T1189', 'HIGH', 'Compromised website delivering exploit'),
        (cat_initial_access, 'Exploit Public-Facing Application', 'T1190', 'CRITICAL', 'Exploitation of web server vulnerability');

    -- Execution attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_execution, 'PowerShell Script Execution', 'T1059.001', 'HIGH', 'Malicious PowerShell script'),
        (cat_execution, 'Command-Line Interface', 'T1059', 'MEDIUM', 'Command shell execution'),
        (cat_execution, 'Windows Management Instrumentation', 'T1047', 'HIGH', 'WMI-based execution'),
        (cat_execution, 'Scheduled Task Execution', 'T1053.005', 'MEDIUM', 'Task scheduler abuse');

    -- Persistence attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_persistence, 'Registry Run Keys', 'T1547.001', 'HIGH', 'Persistence via registry modification'),
        (cat_persistence, 'Scheduled Task Creation', 'T1053.005', 'MEDIUM', 'Persistence via scheduled tasks'),
        (cat_persistence, 'Service Creation', 'T1543.003', 'HIGH', 'Malicious Windows service');

    -- Privilege Escalation attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_privilege_esc, 'Bypass User Account Control', 'T1548.002', 'HIGH', 'UAC bypass technique'),
        (cat_privilege_esc, 'Access Token Manipulation', 'T1134', 'CRITICAL', 'Token theft or impersonation'),
        (cat_privilege_esc, 'Exploitation for Privilege Escalation', 'T1068', 'CRITICAL', 'Local privilege escalation exploit');

    -- Defense Evasion attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_defense_evasion, 'Obfuscated Files or Information', 'T1027', 'MEDIUM', 'Code obfuscation'),
        (cat_defense_evasion, 'Process Injection', 'T1055', 'HIGH', 'Code injection into legitimate process'),
        (cat_defense_evasion, 'Disable Security Tools', 'T1562.001', 'CRITICAL', 'Attempt to disable EDR/AV'),
        (cat_defense_evasion, 'Rootkit', 'T1014', 'CRITICAL', 'Kernel-level hiding mechanism');

    -- Credential Access attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_credential_access, 'OS Credential Dumping - LSASS', 'T1003.001', 'CRITICAL', 'Memory credential theft'),
        (cat_credential_access, 'Brute Force', 'T1110', 'HIGH', 'Password guessing attack'),
        (cat_credential_access, 'Keylogging', 'T1056.001', 'HIGH', 'Keystroke capture');

    -- Lateral Movement attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_lateral_movement, 'Remote Services - SMB/Windows Admin Shares', 'T1021.002', 'HIGH', 'Lateral movement via SMB'),
        (cat_lateral_movement, 'Remote Services - RDP', 'T1021.001', 'MEDIUM', 'Lateral movement via RDP'),
        (cat_lateral_movement, 'Pass the Hash', 'T1550.002', 'CRITICAL', 'Credential reuse attack');

    -- Impact attacks
    INSERT INTO attacks (category_id, name, mitre_technique_id, severity, description)
    VALUES 
        (cat_impact, 'Data Encrypted for Impact (Ransomware)', 'T1486', 'CRITICAL', 'Ransomware encryption'),
        (cat_impact, 'Service Stop', 'T1489', 'HIGH', 'Stopping critical services'),
        (cat_impact, 'Data Destruction', 'T1485', 'CRITICAL', 'Wiping or corrupting data');
END $$;

-- ============================================
-- SAMPLE VENDORS (EDR/XDR Solutions)
-- ============================================
INSERT INTO vendors (name, vendor_type, description, test_version, test_date)
VALUES 
    ('CrowdStrike Falcon', 'XDR', 'Cloud-native XDR platform', '7.12', '2024-11-15'),
    ('Microsoft Defender for Endpoint', 'XDR', 'Microsoft integrated XDR solution', 'Nov 2024', '2024-11-20'),
    ('SentinelOne Singularity', 'XDR', 'AI-powered XDR platform', 'v23.4', '2024-11-18'),
    ('Palo Alto Cortex XDR', 'XDR', 'Network-integrated XDR', '8.2', '2024-11-10'),
    ('Trend Micro Vision One', 'XDR', 'Enterprise XDR solution', 'v7.1', '2024-11-12');

-- ============================================
-- SAMPLE CONTEXT PROFILES
-- ============================================
INSERT INTO context_profiles (name, industry, company_size, security_maturity, description)
VALUES 
    ('Finance - Large Enterprise', 'Finance', 'Enterprise', 'Advanced', 'Large financial institution with mature security program'),
    ('Healthcare - Medium Business', 'Healthcare', 'Medium', 'Intermediate', 'Medium-sized healthcare provider with growing security'),
    ('Manufacturing - Small Business', 'Manufacturing', 'Small', 'Basic', 'Small manufacturer with basic security needs'),
    ('Technology - Startup', 'Technology', 'Small', 'Intermediate', 'Tech startup with security-aware culture'),
    ('Retail - Large Enterprise', 'Retail', 'Enterprise', 'Intermediate', 'Large retail chain with distributed infrastructure');

-- ============================================
-- SAMPLE CONTEXT WEIGHTS
-- ============================================
-- These weights demonstrate how different contexts prioritize different threats
DO $$
DECLARE
    ctx_finance UUID;
    ctx_healthcare UUID;
    ctx_manufacturing UUID;
    cat_credential UUID;
    cat_ransomware UUID;
    cat_initial_access UUID;
    cat_lateral_movement UUID;
BEGIN
    SELECT id INTO ctx_finance FROM context_profiles WHERE name = 'Finance - Large Enterprise';
    SELECT id INTO ctx_healthcare FROM context_profiles WHERE name = 'Healthcare - Medium Business';
    SELECT id INTO ctx_manufacturing FROM context_profiles WHERE name = 'Manufacturing - Small Business';
    
    SELECT id INTO cat_credential FROM attack_categories WHERE name = 'Credential Access';
    SELECT id INTO cat_ransomware FROM attack_categories WHERE name = 'Impact';
    SELECT id INTO cat_initial_access FROM attack_categories WHERE name = 'Initial Access';
    SELECT id INTO cat_lateral_movement FROM attack_categories WHERE name = 'Lateral Movement';

    -- Finance priorities: credential theft and lateral movement
    INSERT INTO context_weights (context_profile_id, attack_category_id, weight, rationale)
    VALUES 
        (ctx_finance, cat_credential, 3.0, 'Financial data highly targeted, credential theft critical'),
        (ctx_finance, cat_lateral_movement, 2.5, 'Large network, lateral movement is high risk'),
        (ctx_finance, cat_ransomware, 2.0, 'Business continuity critical');

    -- Healthcare priorities: ransomware and initial access
    INSERT INTO context_weights (context_profile_id, attack_category_id, weight, rationale)
    VALUES 
        (ctx_healthcare, cat_ransomware, 3.5, 'Patient care disruption unacceptable, ransomware #1 threat'),
        (ctx_healthcare, cat_initial_access, 2.0, 'Phishing common vector in healthcare'),
        (ctx_healthcare, cat_credential, 1.5, 'Patient data protection requirement');

    -- Manufacturing priorities: ransomware and availability
    INSERT INTO context_weights (context_profile_id, attack_category_id, weight, rationale)
    VALUES 
        (ctx_manufacturing, cat_ransomware, 4.0, 'Production downtime extremely costly'),
        (ctx_manufacturing, cat_initial_access, 1.5, 'Basic security awareness, phishing risk moderate');
END $$;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE scoring_rules IS 'Only one rule should be active at a time';
