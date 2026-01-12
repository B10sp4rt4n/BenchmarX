"""
Benchmark Management Page for BenchmarX
Human-controlled benchmark import and score calculation
"""

import streamlit as st
import pandas as pd
from datetime import datetime
from database import DatabaseManager
from scoring import ScoringEngine

def show_benchmark_manager(db: DatabaseManager, scoring_engine: ScoringEngine):
    """Display benchmark management interface"""
    
    st.markdown('<div class="main-header">📊 Benchmark Manager</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Gestión de reportes de benchmark y recálculo de scores</div>', unsafe_allow_html=True)
    
    st.markdown('<div class="warning-box">🧠 <strong>Human Control:</strong> Todos los benchmarks son registrados manualmente. El recálculo de scores es explícito y humano.</div>', unsafe_allow_html=True)
    
    st.markdown("---")
    
    tabs = st.tabs(["📋 Benchmarks", "➕ New Benchmark", "🔄 Recalculate Scores", "📈 Compare"])
    
    # ==============================================
    # TAB: Benchmarks List
    # ==============================================
    with tabs[0]:
        st.subheader("📋 Registered Benchmarks")
        
        benchmarks = db.get_all_benchmarks()
        
        if benchmarks:
            for benchmark in benchmarks:
                with st.expander(f"{'🟢' if benchmark['is_active'] else '⚪'} {benchmark['name']} - {benchmark['report_date']}"):
                    col1, col2, col3 = st.columns(3)
                    
                    with col1:
                        st.markdown(f"**Source:** {benchmark['source']}")
                        st.markdown(f"**Report Date:** {benchmark['report_date']}")
                    
                    with col2:
                        st.markdown(f"**Imported:** {benchmark['imported_at']}")
                        if benchmark.get('imported_by'):
                            st.markdown(f"**By:** {benchmark['imported_by']}")
                    
                    with col3:
                        if benchmark['is_active']:
                            st.success("✅ Active Benchmark")
                        else:
                            if st.button(f"Set as Active", key=f"activate_{benchmark['id']}"):
                                if db.set_active_benchmark(benchmark['id']):
                                    st.success("✅ Benchmark activated!")
                                    st.rerun()
                    
                    if benchmark.get('description'):
                        st.markdown(f"**Description:** {benchmark['description']}")
                    
                    # Show stats
                    stats = db.get_benchmark_stats(benchmark['id'])
                    if stats:
                        st.markdown("---")
                        col1, col2, col3, col4 = st.columns(4)
                        col1.metric("Vendors", stats.get('vendor_count', 0))
                        col2.metric("Attacks", stats.get('attack_count', 0))
                        col3.metric("Detections", stats.get('detection_count', 0))
                        col4.metric("Active", stats.get('active_count', 0))
        else:
            st.info("No benchmarks registered yet. Create your first benchmark in the 'New Benchmark' tab.")
    
    # ==============================================
    # TAB: New Benchmark
    # ==============================================
    with tabs[1]:
        st.subheader("➕ Register New Benchmark")
        
        st.markdown("""
        **⚠️ Important:** 
        - A benchmark is NOT a PDF file uploaded to the system
        - A benchmark is a structured data import from test lab results
        - This form registers the benchmark metadata
        - Detection results must be imported separately (via SQL or import tool)
        """)
        
        with st.form("new_benchmark_form"):
            name = st.text_input(
                "Benchmark Name*",
                placeholder="e.g., AVLab EDR/XDR Q2 2025",
                help="Descriptive name for this benchmark report"
            )
            
            col1, col2 = st.columns(2)
            
            with col1:
                source = st.selectbox(
                    "Source*",
                    ["AVLab", "AV-Comparatives", "SE Labs", "MITRE ATT&CK Evaluations", "Other"],
                    help="Test laboratory or certification body"
                )
            
            with col2:
                report_date = st.date_input(
                    "Report Date*",
                    help="Date when the test report was published"
                )
            
            description = st.text_area(
                "Description",
                placeholder="Brief description of this benchmark (methodology, scope, etc.)",
                help="Optional: Add context about this benchmark"
            )
            
            imported_by = st.text_input(
                "Imported By",
                placeholder="Your name or identifier",
                help="Who is registering this benchmark (for audit trail)"
            )
            
            st.markdown("---")
            
            st.markdown("**Next Steps After Registration:**")
            st.markdown("1. Import detection results (SQL or import tool)")
            st.markdown("2. Go to 'Recalculate Scores' tab")
            st.markdown("3. Trigger score calculation")
            
            submitted = st.form_submit_button("✅ Register Benchmark", type="primary")
            
            if submitted:
                if name and source and report_date:
                    benchmark_id = db.create_benchmark(
                        name=name,
                        source=source,
                        report_date=str(report_date),
                        description=description,
                        imported_by=imported_by
                    )
                    
                    if benchmark_id:
                        st.success(f"✅ Benchmark '{name}' registered successfully!")
                        st.info(f"Benchmark ID: {benchmark_id}")
                        st.markdown("**Next:** Import detection results for this benchmark.")
                        st.rerun()
                    else:
                        st.error("❌ Failed to register benchmark. Check if it already exists.")
                else:
                    st.error("❌ Please fill in all required fields (Name, Source, Report Date)")
    
    # ==============================================
    # TAB: Recalculate Scores
    # ==============================================
    with tabs[2]:
        st.subheader("🔄 Recalculate Scores")
        
        st.markdown("""
        **Human-Triggered Calculation:**
        - Select a benchmark
        - Review what will be calculated
        - Explicitly trigger the calculation
        - Monitor progress and results
        
        **This is NOT automatic.** You control when scores are computed.
        """)
        
        benchmarks = db.get_all_benchmarks()
        
        if benchmarks:
            benchmark_names = [f"{b['name']} ({b['report_date']})" for b in benchmarks]
            selected_benchmark_name = st.selectbox(
                "Select Benchmark to Recalculate:",
                benchmark_names
            )
            
            selected_benchmark = benchmarks[benchmark_names.index(selected_benchmark_name)]
            
            st.markdown("---")
            
            # Show benchmark info
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown(f"**Benchmark:** {selected_benchmark['name']}")
                st.markdown(f"**Source:** {selected_benchmark['source']}")
                st.markdown(f"**Date:** {selected_benchmark['report_date']}")
            
            with col2:
                stats = db.get_benchmark_stats(selected_benchmark['id'])
                if stats:
                    st.metric("Vendors to Calculate", stats.get('vendor_count', 0))
                    st.metric("Attacks Covered", stats.get('attack_count', 0))
            
            # Get contexts count
            contexts = db.get_all_contexts()
            st.info(f"Scores will be calculated for {len(contexts)} context(s)")
            
            st.markdown("---")
            
            # Calculation button
            col1, col2, col3 = st.columns([2, 1, 2])
            
            with col2:
                if st.button("🚀 Calculate Scores", type="primary", use_container_width=True):
                    with st.spinner("Calculating scores... This may take a moment."):
                        count = scoring_engine.materialize_all_scores(selected_benchmark['id'])
                        
                        if count is not None:
                            st.success(f"✅ Calculation complete!")
                            st.metric("Scores Materialized", count)
                            
                            st.info("🎉 Scores materialized! Go to Rankings or Metabase to view results.")
                        else:
                            st.error("❌ Calculation failed. Check database connection and data.")
        else:
            st.warning("No benchmarks available. Register a benchmark first.")
    
    # ==============================================
    # TAB: Compare Benchmarks
    # ==============================================
    with tabs[3]:
        st.subheader("📈 Compare Benchmarks")
        
        st.markdown("Compare vendor performance across different benchmark reports.")
        
        benchmarks = db.get_all_benchmarks()
        vendors = db.get_all_vendors()
        contexts = db.get_all_contexts()
        
        if benchmarks and vendors and contexts:
            col1, col2 = st.columns(2)
            
            with col1:
                vendor_names = [v['name'] for v in vendors]
                selected_vendor_name = st.selectbox("Select Vendor:", vendor_names)
                selected_vendor = next(v for v in vendors if v['name'] == selected_vendor_name)
            
            with col2:
                context_names = [c['name'] for c in contexts]
                selected_context_name = st.selectbox("Select Context:", context_names)
                selected_context = next(c for c in contexts if c['name'] == selected_context_name)
            
            # Multiselect benchmarks
            benchmark_names = [f"{b['name']} ({b['report_date']})" for b in benchmarks]
            selected_benchmark_names = st.multiselect(
                "Select Benchmarks to Compare:",
                benchmark_names,
                default=benchmark_names[:min(3, len(benchmark_names))]
            )
            
            if selected_benchmark_names:
                selected_benchmark_ids = [
                    benchmarks[benchmark_names.index(name)]['id']
                    for name in selected_benchmark_names
                ]
                
                if st.button("📊 Compare", type="primary"):
                    comparison = db.call_compare_benchmarks(
                        selected_vendor['id'],
                        selected_context['id'],
                        selected_benchmark_ids
                    )
                    
                    if comparison:
                        df_comparison = pd.DataFrame(comparison)
                        
                        # Display table
                        st.markdown("### Comparison Results")
                        st.dataframe(df_comparison, use_container_width=True, hide_index=True)
                        
                        # Visualization
                        st.markdown("### Score Evolution")
                        import plotly.graph_objects as go
                        
                        fig = go.Figure()
                        fig.add_trace(go.Scatter(
                            x=df_comparison['benchmark_date'],
                            y=df_comparison['score_percentage'],
                            mode='lines+markers',
                            name='Score %',
                            line=dict(color='#1f77b4', width=3),
                            marker=dict(size=10)
                        ))
                        
                        fig.update_layout(
                            title=f"{selected_vendor['name']} Performance Over Time ({selected_context['name']})",
                            xaxis_title="Benchmark Date",
                            yaxis_title="Score %",
                            height=400
                        )
                        
                        st.plotly_chart(fig, use_container_width=True)
                    else:
                        st.info("No comparison data available. Ensure scores have been calculated for these benchmarks.")
        else:
            st.warning("Need at least one benchmark, vendor, and context to compare.")
