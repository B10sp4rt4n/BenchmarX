"""
BenchmarX - Dynamic EDR/XDR Benchmark Platform
Streamlit Application

Human-governed decision interface with simulation capabilities.
Executes only predefined, human-approved scoring logic.
"""

import streamlit as st
import pandas as pd
from typing import Dict, List, Optional
import plotly.express as px
import plotly.graph_objects as go
from database import DatabaseManager
from scoring import ScoringEngine

# Page configuration
st.set_page_config(
    page_title="BenchmarX - EDR/XDR Benchmark",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize database and scoring engine
@st.cache_resource
def init_services():
    """Initialize database connection and scoring engine"""
    db = DatabaseManager()
    scoring = ScoringEngine(db)
    return db, scoring

db, scoring_engine = init_services()

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        margin-bottom: 0.5rem;
    }
    .sub-header {
        font-size: 1.2rem;
        color: #666;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
    }
    .warning-box {
        background-color: #fff3cd;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #ffc107;
        margin: 1rem 0;
    }
</style>
""", unsafe_allow_html=True)

# Sidebar navigation
st.sidebar.title("🛡️ BenchmarX")
st.sidebar.markdown("---")

page = st.sidebar.radio(
    "Navegación",
    ["🏠 Dashboard", "📊 Benchmarks", "📊 Rankings", "🔍 Vendor Deep Dive", "🧪 What-If Simulator", "⚙️ Context Manager", "📈 Reports"]
)

st.sidebar.markdown("---")
st.sidebar.markdown("### 🧠 Human-Governed Platform")
st.sidebar.info(
    "BenchmarX ejecuta solo lógica de scoring predefinida y aprobada por humanos. "
    "Las recomendaciones son determinísticas y totalmente explicables."
)

# ==============================================
# PAGE: Dashboard
# ==============================================
if page == "🏠 Dashboard":
    st.markdown('<div class="main-header">🛡️ BenchmarX Dashboard</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Dynamic EDR/XDR Benchmark Platform - Context-Aware Decision Intelligence</div>', unsafe_allow_html=True)
    
    # Overview metrics
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        vendor_count = db.get_vendor_count()
        st.metric("Vendors Tested", vendor_count)
    
    with col2:
        attack_count = db.get_attack_count()
        st.metric("Attack Techniques", attack_count)
    
    with col3:
        context_count = db.get_context_count()
        st.metric("Business Contexts", context_count)
    
    with col4:
        detection_count = db.get_detection_count()
        st.metric("Detection Results", detection_count)
    
    st.markdown("---")
    
    # Quick context selector
    st.subheader("🎯 Vista Rápida por Contexto")
    contexts = db.get_all_contexts()
    
    if contexts:
        context_names = [c['name'] for c in contexts]
        selected_context = st.selectbox("Selecciona tu contexto de negocio:", context_names)
        
        if selected_context:
            context = next(c for c in contexts if c['name'] == selected_context)
            
            col1, col2 = st.columns([2, 1])
            
            with col1:
                st.markdown(f"**Industria:** {context['industry']}")
                st.markdown(f"**Tamaño:** {context['company_size']}")
                st.markdown(f"**Madurez de Seguridad:** {context['security_maturity']}")
            
            with col2:
                if st.button("🚀 Ver Ranking Completo", key="quick_ranking"):
                    st.session_state['selected_context'] = context['id']
                    st.rerun()
            
            # Top 3 vendors for this context
            st.markdown("#### 🏆 Top 3 Vendors para este Contexto")
            rankings = scoring_engine.get_vendor_ranking(context['id'], limit=3)
            
            if rankings:
                for idx, vendor in enumerate(rankings, 1):
                    with st.expander(f"#{idx} - {vendor['vendor_name']} ({vendor['vendor_type']}) - {vendor['score_percentage']:.1f}%"):
                        col1, col2, col3 = st.columns(3)
                        col1.metric("Score", f"{vendor['total_score']:.0f}/{vendor['max_possible_score']:.0f}")
                        col2.metric("Active Detections", vendor['active_count'])
                        col3.metric("Dynamic Detections", vendor['dynamic_count'])
    
    st.markdown("---")
    
    # System status
    st.subheader("⚙️ Estado del Sistema")
    col1, col2 = st.columns(2)
    
    with col1:
        active_rule = db.get_active_scoring_rule()
        if active_rule:
            st.success(f"✅ Scoring Rule Activa: **{active_rule['version']}**")
            st.markdown(f"- ACTIVE: {active_rule['detection_active_points']} pts")
            st.markdown(f"- DYNAMIC: {active_rule['detection_dynamic_points']} pts")
            st.markdown(f"- NO_EVID: {active_rule['detection_no_evid_points']} pts")
        else:
            st.error("❌ No hay scoring rule activa")
    
    with col2:
        st.info("🧠 **Arquitectura**")
        st.markdown("- ✅ PostgreSQL (Neon)")
        st.markdown("- ✅ Streamlit (Simulación)")
        st.markdown("- ✅ Metabase (BI)")
        st.markdown("- ✅ Human-defined logic only")

# ==============================================
# PAGE: Benchmark Manager
# ==============================================
elif page == "📊 Benchmarks":
    from benchmark_manager import show_benchmark_manager
    show_benchmark_manager(db, scoring_engine)

# ==============================================
# PAGE: Rankings
# ==============================================
elif page == "📊 Rankings":
    st.markdown('<div class="main-header">📊 Vendor Rankings</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Rankings dinámicos basados en contexto de negocio</div>', unsafe_allow_html=True)
    
    # Context selector
    contexts = db.get_all_contexts()
    
    if contexts:
        col1, col2 = st.columns([3, 1])
        
        with col1:
            context_names = [c['name'] for c in contexts]
            selected_context_name = st.selectbox("Selecciona contexto:", context_names)
            context = next(c for c in contexts if c['name'] == selected_context_name)
        
        with col2:
            st.markdown("#### Contexto Seleccionado")
            st.markdown(f"🏢 {context['industry']}")
            st.markdown(f"📏 {context['company_size']}")
            st.markdown(f"🎓 {context['security_maturity']}")
        
        st.markdown("---")
        
        # Calculate rankings
        with st.spinner("Calculando rankings..."):
            rankings = scoring_engine.get_vendor_ranking(context['id'])
        
        if rankings:
            # Rankings table
            st.subheader("🏆 Ranking de Vendors")
            
            df_rankings = pd.DataFrame(rankings)
            
            # Format for display
            df_display = df_rankings[['rank', 'vendor_name', 'vendor_type', 'score_percentage', 'active_count', 'dynamic_count', 'no_evid_count']].copy()
            df_display.columns = ['Rank', 'Vendor', 'Type', 'Score %', 'Active', 'Dynamic', 'No Evidence']
            
            # Color code by rank
            def highlight_rank(row):
                if row['Rank'] == 1:
                    return ['background-color: #d4edda'] * len(row)
                elif row['Rank'] == 2:
                    return ['background-color: #d1ecf1'] * len(row)
                elif row['Rank'] == 3:
                    return ['background-color: #fff3cd'] * len(row)
                else:
                    return [''] * len(row)
            
            styled_df = df_display.style.apply(highlight_rank, axis=1)
            st.dataframe(styled_df, use_container_width=True, hide_index=True)
            
            # Visualization
            st.markdown("---")
            st.subheader("📈 Visualización Comparativa")
            
            tab1, tab2 = st.tabs(["Score Comparison", "Detection Breakdown"])
            
            with tab1:
                fig = px.bar(
                    df_rankings,
                    x='vendor_name',
                    y='score_percentage',
                    color='vendor_type',
                    title='Score Percentage por Vendor',
                    labels={'vendor_name': 'Vendor', 'score_percentage': 'Score %', 'vendor_type': 'Type'},
                    text='score_percentage'
                )
                fig.update_traces(texttemplate='%{text:.1f}%', textposition='outside')
                fig.update_layout(height=500)
                st.plotly_chart(fig, use_container_width=True)
            
            with tab2:
                # Detection breakdown
                detection_data = []
                for vendor in rankings:
                    detection_data.extend([
                        {'Vendor': vendor['vendor_name'], 'Estado': 'Active', 'Count': vendor['active_count']},
                        {'Vendor': vendor['vendor_name'], 'Estado': 'Dynamic', 'Count': vendor['dynamic_count']},
                        {'Vendor': vendor['vendor_name'], 'Estado': 'No Evidence', 'Count': vendor['no_evid_count']}
                    ])
                
                df_detection = pd.DataFrame(detection_data)
                
                fig = px.bar(
                    df_detection,
                    x='Vendor',
                    y='Count',
                    color='Estado',
                    title='Distribución de Detecciones por Vendor',
                    barmode='stack',
                    color_discrete_map={'Active': '#28a745', 'Dynamic': '#ffc107', 'No Evidence': '#dc3545'}
                )
                fig.update_layout(height=500)
                st.plotly_chart(fig, use_container_width=True)
        else:
            st.warning("No hay datos de ranking disponibles para este contexto.")
    else:
        st.warning("No hay contextos configurados. Ve a 'Context Manager' para crear uno.")

# ==============================================
# PAGE: Vendor Deep Dive
# ==============================================
elif page == "🔍 Vendor Deep Dive":
    st.markdown('<div class="main-header">🔍 Vendor Deep Dive</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Análisis detallado de capacidades de detección</div>', unsafe_allow_html=True)
    
    vendors = db.get_all_vendors()
    
    if vendors:
        vendor_names = [v['name'] for v in vendors]
        selected_vendor_name = st.selectbox("Selecciona un vendor:", vendor_names)
        vendor = next(v for v in vendors if v['name'] == selected_vendor_name)
        
        # Vendor info
        col1, col2, col3, col4 = st.columns(4)
        col1.metric("Type", vendor['vendor_type'])
        col2.metric("Version Tested", vendor.get('test_version', 'N/A'))
        col3.metric("Test Date", vendor.get('test_date', 'N/A'))
        
        st.markdown("---")
        
        # Category coverage
        st.subheader("📊 Cobertura por Categoría de Ataque")
        
        coverage = scoring_engine.get_category_coverage(vendor['id'])
        
        if coverage:
            df_coverage = pd.DataFrame(coverage)
            
            # Heatmap visualization
            fig = px.bar(
                df_coverage,
                x='category_name',
                y='coverage_percentage',
                title='Porcentaje de Cobertura por Categoría MITRE',
                labels={'category_name': 'Categoría', 'coverage_percentage': 'Cobertura %'},
                text='coverage_percentage',
                color='coverage_percentage',
                color_continuous_scale='RdYlGn'
            )
            fig.update_traces(texttemplate='%{text:.1f}%', textposition='outside')
            fig.update_layout(height=500, xaxis_tickangle=-45)
            st.plotly_chart(fig, use_container_width=True)
            
            # Detailed table
            st.markdown("#### Detalle por Categoría")
            df_display = df_coverage[['category_name', 'total_attacks', 'active_detections', 'dynamic_detections', 'no_evidence', 'coverage_percentage']].copy()
            df_display.columns = ['Categoría', 'Total Ataques', 'Active', 'Dynamic', 'No Evidence', 'Cobertura %']
            st.dataframe(df_display, use_container_width=True, hide_index=True)
        else:
            st.warning("No hay datos de cobertura para este vendor.")
        
        st.markdown("---")
        
        # Performance across contexts
        st.subheader("🎯 Performance por Contexto")
        
        contexts = db.get_all_contexts()
        context_performance = []
        
        for context in contexts:
            rankings = scoring_engine.get_vendor_ranking(context['id'])
            vendor_rank = next((r for r in rankings if r['vendor_name'] == vendor['name']), None)
            if vendor_rank:
                context_performance.append({
                    'Context': context['name'],
                    'Rank': vendor_rank['rank'],
                    'Score %': vendor_rank['score_percentage']
                })
        
        if context_performance:
            df_perf = pd.DataFrame(context_performance)
            
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                x=df_perf['Context'],
                y=df_perf['Score %'],
                mode='lines+markers',
                name='Score %',
                line=dict(color='#1f77b4', width=3),
                marker=dict(size=10)
            ))
            fig.update_layout(
                title=f'Performance de {vendor["name"]} por Contexto',
                xaxis_title='Contexto',
                yaxis_title='Score %',
                height=400,
                xaxis_tickangle=-45
            )
            st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("No hay vendors configurados en el sistema.")

# ==============================================
# PAGE: What-If Simulator
# ==============================================
elif page == "🧪 What-If Simulator":
    st.markdown('<div class="main-header">🧪 What-If Simulator</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Simula cambios en contexto y pesos para evaluar impacto</div>', unsafe_allow_html=True)
    
    st.markdown('<div class="warning-box">⚠️ <strong>Simulación Only:</strong> Los cambios aquí no afectan la base de datos. Usa esto para exploración y validación.</div>', unsafe_allow_html=True)
    
    st.markdown("### 🎛️ Configuración de Simulación")
    
    # Base context selection
    contexts = db.get_all_contexts()
    if contexts:
        context_names = [c['name'] for c in contexts]
        selected_context_name = st.selectbox("Contexto base:", context_names)
        base_context = next(c for c in contexts if c['name'] == selected_context_name)
        
        st.markdown("---")
        
        # Weight adjustment
        st.subheader("⚖️ Ajuste de Pesos por Categoría")
        st.info("Ajusta los pesos para simular diferentes prioridades de riesgo")
        
        categories = db.get_all_categories()
        category_weights = {}
        
        col1, col2 = st.columns(2)
        
        for idx, category in enumerate(categories):
            current_weight = db.get_category_weight(base_context['id'], category['id']) or 1.0
            
            with col1 if idx % 2 == 0 else col2:
                category_weights[category['id']] = st.slider(
                    f"{category['name']} ({category.get('mitre_tactic', 'N/A')})",
                    min_value=0.0,
                    max_value=5.0,
                    value=float(current_weight),
                    step=0.5,
                    key=f"weight_{category['id']}"
                )
        
        st.markdown("---")
        
        # Run simulation
        if st.button("🚀 Ejecutar Simulación", type="primary"):
            with st.spinner("Calculando escenario simulado..."):
                # Calculate rankings with custom weights
                simulated_rankings = scoring_engine.simulate_ranking_with_weights(
                    base_context['id'],
                    category_weights
                )
                
                # Show results
                st.success("✅ Simulación completada")
                
                # Compare with original
                original_rankings = scoring_engine.get_vendor_ranking(base_context['id'])
                
                col1, col2 = st.columns(2)
                
                with col1:
                    st.markdown("#### 📊 Ranking Original")
                    df_orig = pd.DataFrame(original_rankings)[:5]
                    st.dataframe(df_orig[['rank', 'vendor_name', 'score_percentage']], hide_index=True)
                
                with col2:
                    st.markdown("#### 🧪 Ranking Simulado")
                    df_sim = pd.DataFrame(simulated_rankings)[:5]
                    st.dataframe(df_sim[['rank', 'vendor_name', 'score_percentage']], hide_index=True)
                
                # Highlight changes
                st.markdown("---")
                st.subheader("🔄 Cambios Detectados")
                
                changes = []
                for orig in original_rankings:
                    sim = next((s for s in simulated_rankings if s['vendor_name'] == orig['vendor_name']), None)
                    if sim:
                        rank_change = orig['rank'] - sim['rank']
                        score_change = sim['score_percentage'] - orig['score_percentage']
                        if rank_change != 0 or abs(score_change) > 0.1:
                            changes.append({
                                'Vendor': orig['vendor_name'],
                                'Original Rank': orig['rank'],
                                'Simulated Rank': sim['rank'],
                                'Rank Change': rank_change,
                                'Score Change %': score_change
                            })
                
                if changes:
                    df_changes = pd.DataFrame(changes)
                    st.dataframe(df_changes, use_container_width=True, hide_index=True)
                else:
                    st.info("No se detectaron cambios significativos en el ranking.")
    else:
        st.warning("No hay contextos configurados.")

# ==============================================
# PAGE: Context Manager
# ==============================================
elif page == "⚙️ Context Manager":
    st.markdown('<div class="main-header">⚙️ Context Manager</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Gestiona contextos de negocio y pesos de riesgo</div>', unsafe_allow_html=True)
    
    tab1, tab2 = st.tabs(["📋 View Contexts", "➕ Create Context"])
    
    with tab1:
        contexts = db.get_all_contexts()
        
        if contexts:
            for context in contexts:
                with st.expander(f"📁 {context['name']}"):
                    col1, col2, col3 = st.columns(3)
                    col1.markdown(f"**Industria:** {context['industry']}")
                    col2.markdown(f"**Tamaño:** {context['company_size']}")
                    col3.markdown(f"**Madurez:** {context['security_maturity']}")
                    
                    st.markdown(f"**Descripción:** {context.get('description', 'N/A')}")
                    
                    # Show weights
                    weights = db.get_context_weights(context['id'])
                    if weights:
                        st.markdown("**Pesos configurados:**")
                        for weight in weights:
                            st.markdown(f"- {weight['category_name']}: **{weight['weight']}x** - {weight.get('rationale', '')}")
        else:
            st.info("No hay contextos configurados todavía.")
    
    with tab2:
        st.markdown("### Crear Nuevo Contexto")
        
        with st.form("create_context"):
            name = st.text_input("Nombre del contexto*")
            
            col1, col2, col3 = st.columns(3)
            with col1:
                industry = st.selectbox("Industria*", [
                    "Finance", "Healthcare", "Manufacturing", "Technology",
                    "Retail", "Government", "Education", "Energy", "Other"
                ])
            with col2:
                company_size = st.selectbox("Tamaño de empresa*", [
                    "Small", "Medium", "Enterprise"
                ])
            with col3:
                security_maturity = st.selectbox("Madurez de seguridad*", [
                    "Basic", "Intermediate", "Advanced"
                ])
            
            description = st.text_area("Descripción")
            
            submitted = st.form_submit_button("✅ Crear Contexto", type="primary")
            
            if submitted:
                if name and industry and company_size and security_maturity:
                    success = db.create_context(name, industry, company_size, security_maturity, description)
                    if success:
                        st.success(f"✅ Contexto '{name}' creado exitosamente!")
                        st.rerun()
                    else:
                        st.error("❌ Error al crear el contexto.")
                else:
                    st.error("❌ Por favor completa todos los campos requeridos.")

# ==============================================
# PAGE: Reports
# ==============================================
elif page == "📈 Reports":
    st.markdown('<div class="main-header">📈 Reports</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Reportes y exportación de datos</div>', unsafe_allow_html=True)
    
    st.info("🔗 Para visualizaciones avanzadas y dashboards interactivos, utiliza **Metabase** (BI layer).")
    
    st.markdown("---")
    
    st.subheader("📊 Reportes Disponibles")
    
    report_type = st.selectbox("Tipo de reporte:", [
        "Vendor Comparison",
        "Context Analysis",
        "Attack Coverage Matrix",
        "Trend Analysis"
    ])
    
    if report_type == "Vendor Comparison":
        st.markdown("### 🆚 Comparación de Vendors")
        
        vendors = db.get_all_vendors()
        contexts = db.get_all_contexts()
        
        if vendors and contexts:
            selected_vendors = st.multiselect(
                "Selecciona vendors a comparar:",
                [v['name'] for v in vendors],
                default=[v['name'] for v in vendors[:3]]
            )
            
            selected_context = st.selectbox(
                "Contexto:",
                [c['name'] for c in contexts]
            )
            
            if st.button("Generar Reporte"):
                context = next(c for c in contexts if c['name'] == selected_context)
                rankings = scoring_engine.get_vendor_ranking(context['id'])
                
                filtered_rankings = [r for r in rankings if r['vendor_name'] in selected_vendors]
                
                if filtered_rankings:
                    df = pd.DataFrame(filtered_rankings)
                    
                    # Comparison table
                    st.dataframe(df[['rank', 'vendor_name', 'vendor_type', 'score_percentage', 'active_count', 'dynamic_count', 'no_evid_count']], use_container_width=True)
                    
                    # Download CSV
                    csv = df.to_csv(index=False)
                    st.download_button(
                        label="📥 Descargar CSV",
                        data=csv,
                        file_name=f"vendor_comparison_{selected_context}.csv",
                        mime="text/csv"
                    )
    
    st.markdown("---")
    st.markdown("### 📊 Metabase Integration")
    st.markdown("Conecta Metabase a tu base de datos Neon para:")
    st.markdown("- Dashboards interactivos en tiempo real")
    st.markdown("- Visualizaciones personalizadas")
    st.markdown("- Reportes programados")
    st.markdown("- Análisis ad-hoc con SQL")

# Footer
st.markdown("---")
st.markdown(
    """
    <div style="text-align: center; color: #666; padding: 2rem 0;">
        <strong>BenchmarX</strong> - Dynamic EDR/XDR Benchmark Platform<br>
        🧠 Human-Governed | 🔍 Explainable | 📊 Context-Aware<br>
        <em>Architecture, scoring, and decisions are human-defined. AI assists, but never decides.</em>
    </div>
    """,
    unsafe_allow_html=True
)
