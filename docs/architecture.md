# Architecture Documentation

## System Overview

BenchmarX is a dynamic, context-aware benchmark platform for EDR/XDR solutions that transforms static certification data into a living decision system.

```
┌─────────────────────────────────────────────────────────────┐
│                     BenchmarX Platform                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   GitHub    │    │  PostgreSQL  │    │  Streamlit   │  │
│  │  Repository │───▶│    (Neon)    │◀───│     App      │  │
│  │             │    │              │    │              │  │
│  │ • SQL       │    │  Single      │    │ • Simulation │  │
│  │ • Rules     │    │  Source of   │    │ • What-If    │  │
│  │ • Docs      │    │  Truth       │    │ • Context    │  │
│  └─────────────┘    └──────────────┘    └──────────────┘  │
│                            │                                │
│                            │ (Read-Only)                    │
│                            ▼                                │
│                     ┌──────────────┐                        │
│                     │   Metabase   │                        │
│                     │      BI      │                        │
│                     │              │                        │
│                     │ • Dashboards │                        │
│                     │ • Reports    │                        │
│                     │ • Analytics  │                        │
│                     └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## Core Principles

### 1. Human-Governed Architecture
- **ALL** scoring logic is human-defined and explicit
- **ALL** context weights are human-assigned with rationale
- **ALL** business rules are deterministic and auditable
- **NO** black-box algorithms or AI-driven scoring
- **NO** autonomous decision-making

### 2. Single Source of Truth
- PostgreSQL (Neon) is the authoritative data store
- All systems read from and write to this single source
- No data duplication across systems
- Complete audit trail in database

### 3. Architectural Evolution

The platform architecture, data model, and scoring mechanisms are intentionally designed to evolve.

**All structural changes, scoring adjustments, and model extensions are:**
- Defined and validated by a human architect
- Versioned and auditable
- Subject to continuous refinement as new contexts, threats, and validation criteria emerge

**This project does not assume a fixed or final architecture.**

Structural adaptability under human governance is a core design requirement. The system is built to accommodate:
- New attack categories and techniques
- Evolving threat landscapes
- Additional business contexts
- Refined scoring methodologies
- Extended data models

All changes follow a controlled process:
1. Human architect proposes change
2. Change is documented and versioned
3. Impact is assessed through simulations
4. Change is tested and validated
5. Change is deployed with full audit trail

### 4. Scoring Philosophy

Scoring within BenchmarX is intentionally:
- **Rule-based**: Explicit, documented rules
- **Deterministic**: Same inputs always produce same outputs
- **Transparent**: All calculations are visible and traceable
- **Easy to inspect and modify**: No hidden complexity

**The scoring logic is NOT designed to be mathematically optimal or predictive.**

Its purpose is to:
- **Make trade-offs explicit**: Show why one vendor ranks higher
- **Enable human review**: Allow experts to validate reasoning
- **Support reasoning and discussion**: Facilitate team decision-making
- **Provide context-aware insights**: Adapt to business priorities

**Auditability and explainability are prioritized over algorithmic complexity.**

This means:
- Simple weighted sums over complex ML models
- Human-readable calculations over optimization algorithms
- Explicit rules over learned patterns
- Traceable logic over black-box predictions

### 5. Advisory Recommendations (Non-Core)

The platform may optionally generate recommendations or insights as advisory outputs.

**These recommendations:**
- Are strictly non-binding
- Never modify core data or scoring logic
- Are clearly separated from the authoritative scoring results
- Require explicit human review and validation
- Are marked as "advisory" in all outputs

**At no point are recommendations applied automatically or treated as a source of truth.**

Example advisory outputs might include:
- "Consider reviewing weight for Ransomware category"
- "Vendor X shows consistent performance across contexts"
- "Gap detected in Credential Access category"

These are informational only and require human judgment to act upon.

### 6. Separation of Concerns

#### Database Layer (PostgreSQL/Neon)
- **Responsibility**: Data persistence, scoring functions, views
- **Contains**: Schema, data, business rules
- **Does NOT contain**: UI logic, simulation logic

#### Simulation Layer (Streamlit)
- **Responsibility**: What-if analysis, context management, validation
- **Contains**: Interactive tools, visualization, user input
- **Does NOT contain**: Business logic (reads from DB), production data modification

#### BI Layer (Metabase)
- **Responsibility**: Reporting, dashboards, executive views
- **Contains**: Read-only queries, visualizations
- **Does NOT contain**: Business logic, write operations

## Data Flow

### 1. Data Ingestion
```
Test Results (e.g., AVLab) 
    ↓
Manual Entry / Import Script
    ↓
PostgreSQL (detection_results table)
    ↓
Audit Log (full traceability)
```

### 2. Scoring Process
```
Human defines context + weights
    ↓
Streamlit calls scoring function
    ↓
PostgreSQL executes deterministic calculation
    ↓
Results stored in scored_results (materialized)
    ↓
Available for querying by Streamlit & Metabase
```

### 3. Decision Making
```
User selects context in Streamlit/Metabase
    ↓
System retrieves pre-calculated rankings
    ↓
User explores with what-if simulations (Streamlit)
    ↓
User views trends and comparisons (Metabase)
    ↓
Human makes informed decision
```

## Components

### Database Schema (PostgreSQL/Neon)

#### Core Tables
- `vendors` - EDR/XDR solutions
- `attacks` - MITRE-aligned attack techniques
- `attack_categories` - MITRE tactics
- `detection_results` - Raw test results (ACTIVE/DYNAMIC/NO_EVID)
- `context_profiles` - Business contexts (industry, size, maturity)
- `context_weights` - Human-defined risk prioritization
- `scored_results` - Materialized scoring outputs
- `scoring_rules` - Explicit scoring logic versions
- `audit_log` - Complete change tracking

#### Functions
- `calculate_vendor_score()` - Core scoring algorithm
- `get_vendor_ranking()` - Ranked vendor list for context
- `get_category_coverage()` - Attack coverage by category
- `materialize_all_scores()` - Batch score calculation

#### Views
- `v_detection_results_complete` - Enriched detection data
- `v_vendor_rankings` - Current rankings by context

### Streamlit Application

#### Pages
1. **Dashboard** - Overview, quick context selection
2. **Rankings** - Context-specific vendor rankings
3. **Vendor Deep Dive** - Detailed vendor analysis
4. **What-If Simulator** - Explore context weight changes
5. **Context Manager** - Create and manage contexts
6. **Reports** - Export and report generation

#### Key Modules
- `app.py` - Main application and UI
- `database.py` - Database connection and queries
- `scoring.py` - Scoring engine wrapper

### Metabase Dashboards

1. **Executive Overview** - High-level KPIs and trends
2. **Context Rankings** - Interactive ranking explorer
3. **Vendor Analysis** - Deep-dive vendor performance
4. **Risk Heatmap** - Coverage gaps and priorities

## Security & Governance

### Access Control
- **Database**: Role-based access (admin, read-write, read-only)
- **Streamlit**: Context management requires authentication (future)
- **Metabase**: Read-only database user, role-based dashboards

### Audit Trail
- All changes logged in `audit_log` table
- Scoring results include calculation metadata (JSON)
- Context weights require rationale (human explanation)
- Scoring rules versioned with creator attribution

### Data Integrity
- Foreign key constraints enforce relationships
- Check constraints validate data ranges
- Unique constraints prevent duplicates
- NOT NULL constraints ensure completeness

## Deployment Architecture

### Development
```
Local PostgreSQL or Neon (dev instance)
    ↑
Streamlit (local: streamlit run app.py)
    +
Metabase (local: Docker container)
```

### Production
```
Neon PostgreSQL (production instance)
    ↑
Streamlit Cloud (or Docker container)
    +
Metabase Cloud (or self-hosted)
```

## Extensibility Points

### Adding New Vendors
1. Insert into `vendors` table
2. Add detection results for all attacks
3. Run `materialize_all_scores()` to calculate rankings

### Adding New Attacks
1. Ensure category exists in `attack_categories`
2. Insert into `attacks` table
3. Add detection results for all vendors
4. Recalculate scores

### Adding New Contexts
1. Insert into `context_profiles` table
2. Define weights in `context_weights` table (with rationale)
3. Calculate scores for new context

### Changing Scoring Logic
1. Create new `scoring_rules` entry (new version)
2. Set `is_active = true` (automatically deactivates others)
3. Run `materialize_all_scores()` with new version
4. Old scores remain for historical comparison

## AI Assistance Boundaries

### AI Usage Policy

BenchmarX may leverage AI-assisted tools (e.g., GitHub Copilot, LLMs) exclusively as productivity and support mechanisms.

**AI tools may:**
- Assist in code generation
- Suggest refactors or improvements
- Help draft documentation or explanations
- Provide debugging assistance
- Generate boilerplate code
- Suggest visualization options

**AI tools must never:**
- Define or alter core scoring logic autonomously
- Set context weights or business rules
- Make autonomous decisions
- Act as a source of truth
- Modify data without explicit human approval
- Become part of the core decision engine
- Execute changes without human validation

**All authoritative logic, structure, and decisions remain under direct human control.**

### Human Authority Checkpoints

The following require explicit human approval:
1. **Scoring rule changes**: Any modification to scoring algorithms
2. **Context weight definitions**: Setting risk prioritization weights
3. **Schema changes**: Database structure modifications
4. **Business logic**: Any rule that affects rankings or decisions
5. **Data modifications**: Changes to vendor, attack, or context data

### AI Assistance vs Core Logic

```
┌───────────────────────────────────────┐
│          HUMAN GOVERNANCE ZONE          │
│  ┌────────────────────────────────┐  │
│  │   CORE DECISION ENGINE      │  │
│  │   - Scoring Logic          │  │
│  │   - Context Weights        │  │
│  │   - Business Rules         │  │
│  │   NO AI ALLOWED            │  │
│  └────────────────────────────────┘  │
│                                       │
│  ┌────────────────────────────────┐  │
│  │   SUPPORT LAYER            │  │
│  │   - Code Generation        │  │
│  │   - Documentation          │  │
│  │   - Debugging              │  │
│  │   AI ASSISTANCE OK         │  │
│  └────────────────────────────────┘  │
└───────────────────────────────────────┘
```

### Traceability

All AI-assisted contributions are:
- Clearly marked in commit messages
- Subject to human review
- Tested before deployment
- Documented for auditability

### AI MAY:
- Suggest code improvements
- Help debug issues
- Generate boilerplate code
- Provide documentation
- Suggest visualization options

### AI MAY NOT:
- Define scoring logic (human only)
- Set context weights (human only)
- Make autonomous decisions
- Alter business rules without approval
- Become part of the core decision engine

## Performance Considerations

### Database Optimization
- Indexes on frequently queried columns
- Materialized scoring results (avoid real-time calculation)
- Efficient JSON storage for metadata
- Connection pooling

### Streamlit Optimization
- `@st.cache_resource` for database connections
- `@st.cache_data` for expensive queries
- Lazy loading of data
- Minimal state management

### Metabase Optimization
- Scheduled dashboard refresh (off-peak)
- Query result caching
- Indexed columns for filters
- Aggregated views for common queries

## Monitoring & Observability

### Database Metrics
- Query performance (slow query log)
- Connection count
- Table sizes
- Index usage

### Application Metrics
- Streamlit session count
- Page load times
- Error rates
- User interactions

### Business Metrics
- Number of contexts created
- Scoring calculations per day
- Most used dashboards
- Simulation frequency

## Disaster Recovery

### Backup Strategy
- Daily automated database backups (Neon)
- SQL schema versioned in Git
- Scoring rules versioned in database
- Metabase configurations exported

### Recovery Procedures
1. Restore database from backup
2. Verify schema version
3. Re-deploy SQL scripts if needed
4. Reconnect Streamlit and Metabase
5. Validate scoring calculations

## Future Enhancements (Roadmap)

### Phase 2
- User authentication and authorization
- API for programmatic access
- Automated test result ingestion
- Custom scoring rule builder (UI)

### Phase 3
- Multi-tenant support
- Advanced reporting (PDF generation)
- Real-time notifications
- Integration with SIEM/SOAR

### Phase 4
- Vendor comparison marketplace
- Community-contributed contexts
- Certification tracking over time
- Predictive trend analysis (human-approved models only)

## Documentation Standards

### Code Documentation
- Docstrings for all functions
- Type hints where applicable
- Inline comments for complex logic
- README files in each directory

### Database Documentation
- Comments on tables and views
- Comments on important columns
- Function documentation in SQL
- Schema diagrams

### User Documentation
- Setup guides (this document)
- User guides for Streamlit app
- Dashboard guides for Metabase
- FAQ and troubleshooting

## Compliance & Standards

### Data Standards
- MITRE ATT&CK framework alignment
- Independent test lab standards (AVLab, etc.)
- Industry-standard severity classifications

### Coding Standards
- Python: PEP 8
- SQL: PostgreSQL best practices
- Git: Conventional commits

### Security Standards
- OWASP Top 10 awareness
- SQL injection prevention (parameterized queries)
- Secure credential management
- Least privilege access
