"""
Scoring Engine for BenchmarX
Implements human-defined, deterministic scoring logic
"""

from typing import List, Dict, Optional
from database import DatabaseManager


class ScoringEngine:
    """
    Scoring Engine - Executes human-defined scoring rules
    
    CRITICAL: This class contains NO AI logic, NO autonomous decisions.
    All scoring rules are explicit, deterministic, and human-approved.
    """
    
    def __init__(self, db: DatabaseManager):
        """
        Initialize scoring engine with database connection
        
        Args:
            db: DatabaseManager instance
        """
        self.db = db
    
    def get_vendor_ranking(self, context_id: str, benchmark_id: str = None, 
                          limit: Optional[int] = None) -> List[Dict]:
        """
        Get ranked list of vendors for a specific context and benchmark
        Uses human-defined scoring function from database
        
        Args:
            context_id: UUID of the context profile
            benchmark_id: UUID of the benchmark (uses active if None)
            limit: Optional limit on number of results
        
        Returns:
            List of vendors with their ranks and scores
        """
        rankings = self.db.call_get_vendor_ranking(context_id, benchmark_id)
        
        if limit and rankings:
            return rankings[:limit]
        
        return rankings
    
    def get_category_coverage(self, vendor_id: str, benchmark_id: str = None) -> List[Dict]:
        """
        Get attack category coverage for a vendor in a specific benchmark
        
        Args:
            vendor_id: UUID of the vendor
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            List of categories with coverage metrics
        """
        return self.db.call_get_category_coverage(vendor_id, benchmark_id)
    
    def calculate_vendor_score(self, vendor_id: str, context_id: str, 
                              benchmark_id: str = None) -> Optional[Dict]:
        """
        Calculate score for a vendor in a specific context and benchmark
        Uses human-defined scoring function
        
        Args:
            vendor_id: UUID of the vendor
            context_id: UUID of the context profile
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            Dictionary with score breakdown
        """
        return self.db.call_calculate_vendor_score(vendor_id, context_id, benchmark_id)
    
    def simulate_ranking_with_weights(self, context_id: str, 
                                     category_weights: Dict[str, float],
                                     benchmark_id: str = None) -> List[Dict]:
        """
        Simulate ranking with custom category weights
        THIS IS A READ-ONLY SIMULATION - does not modify database
        
        Args:
            context_id: UUID of the context profile
            category_weights: Dictionary mapping category_id to weight
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            List of vendors with simulated ranks and scores
        """
        # Store original weights
        original_weights = {}
        
        try:
            # Get all vendors
            vendors = self.db.get_all_vendors()
            
            # Temporarily update weights in a transaction
            simulated_scores = []
            
            for vendor in vendors:
                # For simulation, we calculate score with custom weights
                # This is a simplified version - in production, you'd use a temp table
                score_data = self._calculate_simulated_score(
                    vendor['id'], 
                    context_id, 
                    category_weights,
                    benchmark_id
                )
                
                if score_data:
                    simulated_scores.append({
                        'vendor_id': vendor['id'],
                        'vendor_name': vendor['name'],
                        'vendor_type': vendor['vendor_type'],
                        **score_data
                    })
            
            # Sort by score percentage
            simulated_scores.sort(key=lambda x: x['score_percentage'], reverse=True)
            
            # Add ranks
            for idx, score in enumerate(simulated_scores, 1):
                score['rank'] = idx
            
            return simulated_scores
            
        finally:
            # Restore original weights if needed
            pass
    
    def _calculate_simulated_score(self, vendor_id: str, context_id: str, 
                                   category_weights: Dict[str, float],
                                   benchmark_id: str = None) -> Optional[Dict]:
        """
        Internal method to calculate score with custom weights
        
        Args:
            vendor_id: UUID of the vendor
            context_id: UUID of the context profile
            category_weights: Dictionary mapping category_id to weight
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            Dictionary with score metrics
        """
        # Get scoring rule
        scoring_rule = self.db.get_active_scoring_rule()
        if not scoring_rule:
            return None
        
        active_points = float(scoring_rule['detection_active_points'])
        dynamic_points = float(scoring_rule['detection_dynamic_points'])
        no_evid_points = float(scoring_rule['detection_no_evid_points'])
        
        # Get detection results for this vendor and benchmark
        if benchmark_id:
            # For a specific benchmark, need to filter by benchmark_id
            # This requires a new database method
            detections = self.db.get_detection_results_by_benchmark(vendor_id, benchmark_id)
        else:
            # Use active benchmark
            detections = self.db.get_detection_results(vendor_id)
        
        total_score = 0.0
        max_score = 0.0
        active_count = 0
        dynamic_count = 0
        no_evid_count = 0
        
        for detection in detections:
            # Get category for this attack
            attack_id = detection['id']
            category_id = None
            
            # Find category_id from attacks table
            attacks = self.db.get_all_attacks()
            for attack in attacks:
                if attack['name'] == detection['attack_name']:
                    # Get category
                    categories = self.db.get_all_categories()
                    for cat in categories:
                        if cat['name'] == detection['category_name']:
                            category_id = cat['id']
                            break
                    break
            
            # Get weight for this category
            weight = category_weights.get(category_id, 1.0) if category_id else 1.0
            
            # Calculate points based on detection state
            if detection['detection_state'] == 'ACTIVE':
                points = active_points
                active_count += 1
            elif detection['detection_state'] == 'DYNAMIC':
                points = dynamic_points
                dynamic_count += 1
            else:  # NO_EVID
                points = no_evid_points
                no_evid_count += 1
            
            # Apply weight
            total_score += points * weight
            max_score += active_points * weight
        
        # Calculate percentage
        score_percentage = (total_score / max_score * 100) if max_score > 0 else 0
        
        return {
            'total_score': round(total_score, 2),
            'max_possible_score': round(max_score, 2),
            'score_percentage': round(score_percentage, 2),
            'active_count': active_count,
            'dynamic_count': dynamic_count,
            'no_evid_count': no_evid_count
        }
    
    def materialize_all_scores(self, benchmark_id: str = None) -> int:
        """
        Materialize scores for all vendor-context combinations
        HUMAN-TRIGGERED: Recalculates scores from human-defined rules
        Stores results in scored_results table for auditability
        
        Args:
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            Number of scores materialized
        """
        count = self.db.call_materialize_scores_for_benchmark(benchmark_id)
        return count if count is not None else 0
    
    def explain_score(self, vendor_id: str, context_id: str) -> Dict:
        """
        Generate human-readable explanation of a vendor's score
        Shows exactly how the score was calculated
        
        Args:
            vendor_id: UUID of the vendor
            context_id: UUID of the context profile
        
        Returns:
            Dictionary with detailed score breakdown and explanation
        """
        # Get scored result with calculation metadata
        results = self.db.get_scored_results(context_id=context_id, vendor_id=vendor_id)
        
        if not results:
            return {"error": "No scored results found"}
        
        result = results[0]
        
        # Get scoring rule
        scoring_rule = self.db.get_active_scoring_rule()
        
        # Get context info
        context = self.db.get_context_by_id(context_id)
        
        # Get vendor info
        vendor = self.db.get_vendor_by_id(vendor_id)
        
        explanation = {
            "vendor": vendor['name'] if vendor else "Unknown",
            "context": context['name'] if context else "Unknown",
            "scoring_version": result['scoring_version'],
            "scoring_rule": {
                "active_points": scoring_rule['detection_active_points'],
                "dynamic_points": scoring_rule['detection_dynamic_points'],
                "no_evid_points": scoring_rule['detection_no_evid_points']
            },
            "results": {
                "total_score": result['total_score'],
                "max_possible_score": result['max_possible_score'],
                "score_percentage": result['score_percentage']
            },
            "detection_breakdown": {
                "active": result['detection_active_count'],
                "dynamic": result['detection_dynamic_count'],
                "no_evidence": result['detection_no_evid_count']
            },
            "calculation_metadata": result.get('calculation_metadata', {})
        }
        
        return explanation
    
    def compare_vendors(self, vendor_ids: List[str], context_id: str, 
                       benchmark_id: str = None) -> List[Dict]:
        """
        Compare multiple vendors in a specific context and benchmark
        
        Args:
            vendor_ids: List of vendor UUIDs
            context_id: UUID of the context profile
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            List of vendor comparisons with scores and metrics
        """
        comparisons = []
        
        for vendor_id in vendor_ids:
            score = self.calculate_vendor_score(vendor_id, context_id, benchmark_id)
            vendor = self.db.get_vendor_by_id(vendor_id)
            coverage = self.get_category_coverage(vendor_id, benchmark_id)
            
            if score and vendor:
                comparisons.append({
                    "vendor_id": vendor_id,
                    "vendor_name": vendor['name'],
                    "vendor_type": vendor['vendor_type'],
                    "score": score,
                    "category_coverage": coverage
                })
        
        # Sort by score percentage
        comparisons.sort(key=lambda x: x['score']['score_percentage'], reverse=True)
        
        return comparisons
    
    def get_risk_heatmap(self, vendor_id: str, benchmark_id: str = None) -> Dict:
        """
        Generate risk heatmap data for a vendor
        Shows which attack categories have gaps
        
        Args:
            vendor_id: UUID of the vendor
            benchmark_id: UUID of the benchmark (uses active if None)
        
        Returns:
            Dictionary with heatmap data
        """
        coverage = self.get_category_coverage(vendor_id, benchmark_id)
        vendor = self.db.get_vendor_by_id(vendor_id)
        
        if not coverage or not vendor:
            return {"error": "Data not found"}
        
        # Transform coverage data into heatmap format
        heatmap_data = []
        
        for category in coverage:
            risk_level = self._calculate_risk_level(
                category['coverage_percentage'],
                category['no_evidence']
            )
            
            heatmap_data.append({
                "category": category['category_name'],
                "coverage_percentage": category['coverage_percentage'],
                "active": category['active_detections'],
                "dynamic": category['dynamic_detections'],
                "no_evidence": category['no_evidence'],
                "total": category['total_attacks'],
                "risk_level": risk_level
            })
        
        return {
            "vendor": vendor['name'],
            "heatmap": heatmap_data
        }
    
    def _calculate_risk_level(self, coverage_percentage: float, no_evidence: int) -> str:
        """
        Calculate risk level based on coverage and gaps
        Human-defined risk thresholds
        
        Args:
            coverage_percentage: Percentage of attacks covered
            no_evidence: Number of attacks with no evidence of detection
        
        Returns:
            Risk level: "LOW", "MEDIUM", "HIGH", "CRITICAL"
        """
        if coverage_percentage >= 90 and no_evidence <= 1:
            return "LOW"
        elif coverage_percentage >= 75 and no_evidence <= 3:
            return "MEDIUM"
        elif coverage_percentage >= 50:
            return "HIGH"
        else:
            return "CRITICAL"
