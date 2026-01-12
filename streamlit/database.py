"""
Database Manager for BenchmarX
Handles all database interactions with PostgreSQL/Neon
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import List, Dict, Optional, Any
from contextlib import contextmanager
import streamlit as st


class DatabaseManager:
    """
    Manages database connections and queries.
    All queries are human-defined and deterministic.
    """
    
    def __init__(self):
        """Initialize database connection from environment variables or Streamlit secrets"""
        try:
            # Try Streamlit secrets first
            self.connection_string = st.secrets.get("DATABASE_URL", os.getenv("DATABASE_URL"))
        except:
            # Fallback to environment variable
            self.connection_string = os.getenv("DATABASE_URL")
        
        if not self.connection_string:
            st.error("❌ DATABASE_URL not configured. Set it in .streamlit/secrets.toml or environment variables.")
    
    @contextmanager
    def get_connection(self):
        """Context manager for database connections"""
        conn = None
        try:
            conn = psycopg2.connect(self.connection_string)
            yield conn
        finally:
            if conn:
                conn.close()
    
    def execute_query(self, query: str, params: tuple = None, fetch: bool = True) -> Optional[List[Dict]]:
        """
        Execute a SQL query and return results as list of dicts
        
        Args:
            query: SQL query string
            params: Query parameters (for parameterized queries)
            fetch: Whether to fetch results (False for INSERT/UPDATE/DELETE)
        
        Returns:
            List of dictionaries with query results, or None
        """
        try:
            with self.get_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                    cursor.execute(query, params)
                    
                    if fetch:
                        results = cursor.fetchall()
                        return [dict(row) for row in results]
                    else:
                        conn.commit()
                        return None
        except Exception as e:
            st.error(f"Database error: {str(e)}")
            return None
    
    # ==============================================
    # VENDOR QUERIES
    # ==============================================
    
    def get_all_vendors(self) -> List[Dict]:
        """Get all vendors"""
        query = """
            SELECT id, name, vendor_type, description, test_version, test_date, created_at
            FROM vendors
            ORDER BY name
        """
        return self.execute_query(query) or []
    
    def get_vendor_by_id(self, vendor_id: str) -> Optional[Dict]:
        """Get vendor by ID"""
        query = """
            SELECT id, name, vendor_type, description, test_version, test_date, created_at
            FROM vendors
            WHERE id = %s
        """
        results = self.execute_query(query, (vendor_id,))
        return results[0] if results else None
    
    def get_vendor_count(self) -> int:
        """Get total number of vendors"""
        query = "SELECT COUNT(*) as count FROM vendors"
        result = self.execute_query(query)
        return result[0]['count'] if result else 0
    
    # ==============================================
    # ATTACK QUERIES
    # ==============================================
    
    def get_all_attacks(self) -> List[Dict]:
        """Get all attacks with category information"""
        query = """
            SELECT 
                a.id, a.name, a.mitre_technique_id, a.severity, a.description,
                ac.name as category_name, ac.mitre_tactic
            FROM attacks a
            JOIN attack_categories ac ON a.category_id = ac.id
            ORDER BY ac.name, a.name
        """
        return self.execute_query(query) or []
    
    def get_all_categories(self) -> List[Dict]:
        """Get all attack categories"""
        query = """
            SELECT id, name, mitre_tactic, description
            FROM attack_categories
            ORDER BY name
        """
        return self.execute_query(query) or []
    
    def get_attack_count(self) -> int:
        """Get total number of attacks"""
        query = "SELECT COUNT(*) as count FROM attacks"
        result = self.execute_query(query)
        return result[0]['count'] if result else 0
    
    # ==============================================
    # DETECTION QUERIES
    # ==============================================
    
    def get_detection_results(self, vendor_id: Optional[str] = None) -> List[Dict]:
        """Get detection results, optionally filtered by vendor"""
        if vendor_id:
            query = """
                SELECT * FROM v_detection_results_complete
                WHERE vendor_id = %s
                ORDER BY category_name, attack_name
            """
            params = (vendor_id,)
        else:
            query = """
                SELECT * FROM v_detection_results_complete
                ORDER BY vendor_name, category_name, attack_name
            """
            params = None
        
        return self.execute_query(query, params) or []
    
    def get_detection_results_by_benchmark(self, vendor_id: str, 
                                          benchmark_id: str = None) -> List[Dict]:
        """
        Get detection results filtered by vendor and benchmark
        
        Args:
            vendor_id: UUID of the vendor
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            List of detection results
        """
        if not benchmark_id:
            # Get active benchmark
            active = self.get_active_benchmark()
            if not active:
                return []
            benchmark_id = active['id']
        
        query = """
            SELECT dr.*, 
                   v.name as vendor_name,
                   a.name as attack_name,
                   c.name as category_name
            FROM detection_results dr
            JOIN vendors v ON dr.vendor_id = v.id
            JOIN attacks a ON dr.attack_id = a.id
            JOIN categories c ON a.category_id = c.id
            WHERE dr.vendor_id = %s 
              AND dr.benchmark_id = %s
            ORDER BY c.name, a.name
        """
        return self.execute_query(query, (vendor_id, benchmark_id)) or []
    
    def get_detection_count(self) -> int:
        """Get total number of detection results"""
        query = "SELECT COUNT(*) as count FROM detection_results"
        result = self.execute_query(query)
        return result[0]['count'] if result else 0
    
    # ==============================================
    # CONTEXT QUERIES
    # ==============================================
    
    def get_all_contexts(self) -> List[Dict]:
        """Get all context profiles"""
        query = """
            SELECT id, name, industry, company_size, security_maturity, description, created_at
            FROM context_profiles
            ORDER BY name
        """
        return self.execute_query(query) or []
    
    def get_context_by_id(self, context_id: str) -> Optional[Dict]:
        """Get context by ID"""
        query = """
            SELECT id, name, industry, company_size, security_maturity, description, created_at
            FROM context_profiles
            WHERE id = %s
        """
        results = self.execute_query(query, (context_id,))
        return results[0] if results else None
    
    def get_context_count(self) -> int:
        """Get total number of contexts"""
        query = "SELECT COUNT(*) as count FROM context_profiles"
        result = self.execute_query(query)
        return result[0]['count'] if result else 0
    
    def create_context(self, name: str, industry: str, company_size: str, 
                      security_maturity: str, description: str = None) -> bool:
        """Create a new context profile"""
        query = """
            INSERT INTO context_profiles (name, industry, company_size, security_maturity, description)
            VALUES (%s, %s, %s, %s, %s)
        """
        result = self.execute_query(
            query, 
            (name, industry, company_size, security_maturity, description),
            fetch=False
        )
        return result is None  # None means success (no exception)
    
    # ==============================================
    # BENCHMARK QUERIES
    # ==============================================
    
    def get_all_benchmarks(self) -> List[Dict]:
        """Get all benchmarks ordered by date"""
        query = """
            SELECT id, name, source, report_date, description, imported_at, 
                   imported_by, is_active, metadata
            FROM benchmarks
            ORDER BY report_date DESC, name
        """
        return self.execute_query(query) or []
    
    def get_benchmark_by_id(self, benchmark_id: str) -> Optional[Dict]:
        """Get benchmark by ID"""
        query = """
            SELECT id, name, source, report_date, description, imported_at,
                   imported_by, is_active, metadata
            FROM benchmarks
            WHERE id = %s
        """
        results = self.execute_query(query, (benchmark_id,))
        return results[0] if results else None
    
    def get_active_benchmark(self) -> Optional[Dict]:
        """Get the currently active benchmark"""
        query = """
            SELECT id, name, source, report_date, description, imported_at,
                   imported_by, is_active, metadata
            FROM benchmarks
            WHERE is_active = true
            ORDER BY report_date DESC
            LIMIT 1
        """
        results = self.execute_query(query)
        return results[0] if results else None
    
    def create_benchmark(self, name: str, source: str, report_date: str,
                        description: str = None, imported_by: str = None,
                        metadata: dict = None) -> Optional[str]:
        """Create a new benchmark and return its ID"""
        query = """
            INSERT INTO benchmarks (name, source, report_date, description, imported_by, metadata)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id
        """
        import json
        metadata_json = json.dumps(metadata) if metadata else None
        
        try:
            with self.get_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                    cursor.execute(query, (name, source, report_date, description, imported_by, metadata_json))
                    result = cursor.fetchone()
                    conn.commit()
                    return result['id'] if result else None
        except Exception as e:
            st.error(f"Error creating benchmark: {str(e)}")
            return None
    
    def set_active_benchmark(self, benchmark_id: str) -> bool:
        """Set a benchmark as active (deactivates all others)"""
        query = """
            UPDATE benchmarks SET is_active = false;
            UPDATE benchmarks SET is_active = true WHERE id = %s;
        """
        result = self.execute_query(query, (benchmark_id,), fetch=False)
        return result is None
    
    def get_benchmark_stats(self, benchmark_id: str) -> Dict:
        """Get statistics for a benchmark"""
        query = """
            SELECT 
                COUNT(DISTINCT dr.vendor_id) as vendor_count,
                COUNT(DISTINCT dr.attack_id) as attack_count,
                COUNT(*) as detection_count,
                SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END) as active_count,
                SUM(CASE WHEN dr.detection_state = 'DYNAMIC' THEN 1 ELSE 0 END) as dynamic_count,
                SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END) as no_evid_count
            FROM detection_results dr
            WHERE dr.benchmark_id = %s
        """
        results = self.execute_query(query, (benchmark_id,))
        return results[0] if results else {}
    
    # ==============================================
    # WEIGHT QUERIES
    # ==============================================
    
    def get_context_weights(self, context_id: str) -> List[Dict]:
        """Get all weights for a context"""
        query = """
            SELECT 
                cw.id, cw.weight, cw.rationale,
                ac.name as category_name,
                a.name as attack_name
            FROM context_weights cw
            LEFT JOIN attack_categories ac ON cw.attack_category_id = ac.id
            LEFT JOIN attacks a ON cw.attack_id = a.id
            WHERE cw.context_profile_id = %s
            ORDER BY cw.weight DESC
        """
        return self.execute_query(query, (context_id,)) or []
    
    def get_category_weight(self, context_id: str, category_id: str) -> Optional[float]:
        """Get weight for a specific category in a context"""
        query = """
            SELECT weight
            FROM context_weights
            WHERE context_profile_id = %s AND attack_category_id = %s
        """
        results = self.execute_query(query, (context_id, category_id))
        return float(results[0]['weight']) if results else None
    
    def set_category_weight(self, context_id: str, category_id: str, 
                           weight: float, rationale: str = None) -> bool:
        """Set weight for a category in a context"""
        query = """
            INSERT INTO context_weights (context_profile_id, attack_category_id, weight, rationale)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (context_profile_id, attack_category_id)
            DO UPDATE SET weight = EXCLUDED.weight, rationale = EXCLUDED.rationale, updated_at = CURRENT_TIMESTAMP
        """
        result = self.execute_query(
            query,
            (context_id, category_id, weight, rationale),
            fetch=False
        )
        return result is None
    
    # ==============================================    # BENCHMARK QUERIES
    # ==============================================
    
    def get_all_benchmarks(self) -> List[Dict]:
        """Get all benchmarks"""
        query = """
            SELECT id, name, source, report_date, description, 
                   imported_at, imported_by, is_active, created_at
            FROM benchmarks
            ORDER BY report_date DESC, name
        """
        return self.execute_query(query) or []
    
    def get_benchmark_by_id(self, benchmark_id: str) -> Optional[Dict]:
        """Get benchmark by ID"""
        query = """
            SELECT id, name, source, report_date, description,
                   imported_at, imported_by, is_active, created_at
            FROM benchmarks
            WHERE id = %s
        """
        results = self.execute_query(query, (benchmark_id,))
        return results[0] if results else None
    
    def get_active_benchmark(self) -> Optional[Dict]:
        """Get the currently active benchmark"""
        query = """
            SELECT id, name, source, report_date, description,
                   imported_at, imported_by, is_active, created_at
            FROM benchmarks
            WHERE is_active = true
            LIMIT 1
        """
        results = self.execute_query(query)
        return results[0] if results else None
    
    def create_benchmark(self, name: str, source: str, report_date: str,
                        description: str = None, imported_by: str = None) -> Optional[str]:
        """
        Create a new benchmark
        
        Args:
            name: Benchmark name (e.g., "AVLab EDR/XDR 2025")
            source: Source lab (e.g., "AVLab", "AV-TEST")
            report_date: Date of the report (YYYY-MM-DD)
            description: Optional description
            imported_by: Who imported this benchmark
        
        Returns:
            Benchmark ID if successful, None otherwise
        """
        query = """
            INSERT INTO benchmarks (name, source, report_date, description, imported_by, is_active)
            VALUES (%s, %s, %s, %s, %s, false)
            RETURNING id
        """
        try:
            with self.get_connection() as conn:
                with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                    cursor.execute(query, (name, source, report_date, description, imported_by))
                    result = cursor.fetchone()
                    conn.commit()
                    return str(result['id']) if result else None
        except Exception as e:
            st.error(f"Error creating benchmark: {str(e)}")
            return None
    
    def set_active_benchmark(self, benchmark_id: str) -> bool:
        """
        Set the active benchmark (only one can be active at a time)
        
        Args:
            benchmark_id: UUID of the benchmark to activate
        
        Returns:
            True if successful, False otherwise
        """
        query = """
            SELECT set_active_benchmark(%s)
        """
        result = self.execute_query(query, (benchmark_id,), fetch=True)
        return bool(result[0]['set_active_benchmark']) if result else False
    
    def get_benchmark_detection_count(self, benchmark_id: str) -> int:
        """Get number of detection results for a benchmark"""
        query = """
            SELECT COUNT(*) as count 
            FROM detection_results 
            WHERE benchmark_id = %s
        """
        result = self.execute_query(query, (benchmark_id,))
        return result[0]['count'] if result else 0
    
    def get_benchmark_statistics(self, benchmark_id: str) -> Optional[Dict]:
        """Get statistics for a benchmark"""
        query = """
            SELECT 
                b.id,
                b.name,
                b.source,
                b.report_date,
                COUNT(DISTINCT dr.vendor_id) as vendor_count,
                COUNT(DISTINCT dr.attack_id) as attack_count,
                COUNT(*) as detection_count,
                SUM(CASE WHEN dr.detection_state = 'ACTIVE' THEN 1 ELSE 0 END) as active_count,
                SUM(CASE WHEN dr.detection_state = 'DYNAMIC' THEN 1 ELSE 0 END) as dynamic_count,
                SUM(CASE WHEN dr.detection_state = 'NO_EVID' THEN 1 ELSE 0 END) as no_evid_count
            FROM benchmarks b
            LEFT JOIN detection_results dr ON b.id = dr.benchmark_id
            WHERE b.id = %s
            GROUP BY b.id, b.name, b.source, b.report_date
        """
        results = self.execute_query(query, (benchmark_id,))
        return results[0] if results else None
    
    # ==============================================    # SCORING QUERIES
    # ==============================================
    
    def get_active_scoring_rule(self) -> Optional[Dict]:
        """Get the currently active scoring rule"""
        query = """
            SELECT version, detection_active_points, detection_dynamic_points, 
                   detection_no_evid_points, description, created_by
            FROM scoring_rules
            WHERE is_active = true
            LIMIT 1
        """
        results = self.execute_query(query)
        return results[0] if results else None
    
    def get_scored_results(self, context_id: Optional[str] = None, 
                          vendor_id: Optional[str] = None) -> List[Dict]:
        """Get scored results, optionally filtered"""
        if context_id and vendor_id:
            query = """
                SELECT * FROM scored_results
                WHERE context_profile_id = %s AND vendor_id = %s
                ORDER BY created_at DESC
                LIMIT 1
            """
            params = (context_id, vendor_id)
        elif context_id:
            query = """
                SELECT sr.*, v.name as vendor_name
                FROM scored_results sr
                JOIN vendors v ON sr.vendor_id = v.id
                WHERE sr.context_profile_id = %s
                ORDER BY sr.score_percentage DESC
            """
            params = (context_id,)
        elif vendor_id:
            query = """
                SELECT sr.*, cp.name as context_name
                FROM scored_results sr
                JOIN context_profiles cp ON sr.context_profile_id = cp.id
                WHERE sr.vendor_id = %s
                ORDER BY sr.created_at DESC
            """
            params = (vendor_id,)
        else:
            query = """
                SELECT sr.*, v.name as vendor_name, cp.name as context_name
                FROM scored_results sr
                JOIN vendors v ON sr.vendor_id = v.id
                JOIN context_profiles cp ON sr.context_profile_id = cp.id
                ORDER BY sr.created_at DESC
            """
            params = None
        
        return self.execute_query(query, params) or []
    
    # ==============================================
    # FUNCTION CALLS (Stored Procedures)
    # ==============================================
    
    def call_calculate_vendor_score(self, vendor_id: str, context_id: str, 
                                    benchmark_id: str = None) -> Optional[Dict]:
        """Call the calculate_vendor_score function"""
        if benchmark_id:
            query = """
                SELECT * FROM calculate_vendor_score(%s, %s, %s)
            """
            results = self.execute_query(query, (vendor_id, context_id, benchmark_id))
        else:
            # Use active benchmark if none specified
            active_benchmark = self.get_active_benchmark()
            if not active_benchmark:
                st.warning("No active benchmark found")
                return None
            query = """
                SELECT * FROM calculate_vendor_score(%s, %s, %s)
            """
            results = self.execute_query(query, (vendor_id, context_id, active_benchmark['id']))
        return results[0] if results else None
    
    def call_get_vendor_ranking(self, context_id: str, benchmark_id: str = None) -> List[Dict]:
        """
        Call the get_vendor_ranking function
        
        Args:
            context_id: UUID of the context profile
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            List of ranked vendors
        """
        query = """
            SELECT * FROM get_vendor_ranking(%s, %s)
        """
        return self.execute_query(query, (context_id, benchmark_id)) or []
    
    def call_get_category_coverage(self, vendor_id: str, benchmark_id: str = None) -> List[Dict]:
        """
        Call the get_category_coverage function
        
        Args:
            vendor_id: UUID of the vendor
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            List of categories with coverage metrics
        """
        query = """
            SELECT * FROM get_category_coverage(%s, %s)
        """
        return self.execute_query(query, (vendor_id, benchmark_id)) or []
    
    def call_materialize_scores_for_benchmark(self, benchmark_id: str = None) -> Optional[int]:
        """
        Call materialize_scores_for_benchmark function
        HUMAN-TRIGGERED: Recalculate all scores for a specific benchmark
        
        Args:
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            Number of scores materialized
        """
        query = """
            SELECT materialize_scores_for_benchmark(%s) as count
        """
        results = self.execute_query(query, (benchmark_id,))
        return results[0]['count'] if results else None
    
    def call_compare_vendor_across_benchmarks(self, vendor_id: str, 
                                             context_id: str) -> List[Dict]:
        """
        Compare vendor performance across all benchmarks
        
        Args:
            vendor_id: UUID of the vendor
            context_id: UUID of the context profile
        
        Returns:
            List of benchmark comparisons with score changes
        """
        query = """
            SELECT * FROM compare_vendor_across_benchmarks(%s, %s)
        """
        return self.execute_query(query, (vendor_id, context_id)) or []
