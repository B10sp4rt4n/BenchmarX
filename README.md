# 🛡️ BenchmarX - Dynamic EDR/XDR Benchmark Platform

> **Transform static certification data into context-aware decision intelligence**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)

BenchmarX is a dynamic, context-aware benchmark platform for EDR/XDR solutions. Built on independent test results (e.g., AVLab), it transforms static certifications into a living decision system where rankings adapt to your business context—industry, company size, and security maturity.

## 🎯 What Makes BenchmarX Different

- **Context-Aware**: Rankings change based on YOUR business priorities
- **Human-Governed**: No black-box AI—all scoring logic is explicit and auditable
- **Explainable**: Every score can be traced back to attacks and detection states
- **Dynamic**: What-if simulations to explore different scenarios
- **Single Source of Truth**: PostgreSQL-backed with complete audit trail

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- PostgreSQL 14+ or [Neon](https://neon.tech) account (free tier available)

### Installation

```bash
# Clone repository
git clone https://github.com/B10sp4rt4n/BenchmarX.git
cd BenchmarX

# Configure environment
cp .env.example .env
# Edit .env with your DATABASE_URL

# Deploy database
./scripts/setup_database.sh

# Start Streamlit app
./scripts/start_streamlit.sh
```

Open http://localhost:8501 in your browser 🎉

📖 **Full setup guide**: [docs/quickstart.md](docs/quickstart.md)

## 🧩 Architecture

```
┌─────────────────────────────────────────────────────┐
│                  BenchmarX Platform                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐    ┌──────────────┐              │
│  │ PostgreSQL   │    │  Streamlit   │              │
│  │   (Neon)     │◀───│     App      │              │
│  │              │    │              │              │
│  │ Single       │    │ • Simulation │              │
│  │ Source of    │    │ • What-If    │              │
│  │ Truth        │    │ • Context    │              │
│  └──────────────┘    └──────────────┘              │
│         │                                           │
│         │ (Read-Only)                               │
│         ▼                                           │
│  ┌──────────────┐                                   │
│  │   Metabase   │                                   │
│  │      BI      │                                   │
│  │              │                                   │
│  │ • Dashboards │                                   │
│  │ • Reports    │                                   │
│  └──────────────┘                                   │
└─────────────────────────────────────────────────────┘
```

## ✨ Key Features

### 🎯 Context-Aware Rankings
Rankings adapt based on:
- **Industry** (Finance, Healthcare, Manufacturing, etc.)
- **Company Size** (Small, Medium, Enterprise)
- **Security Maturity** (Basic, Intermediate, Advanced)

### 🧪 What-If Simulations
- Adjust category weights in real-time
- Compare scenarios side-by-side
- Validate decisions before committing

### 📊 Risk Heatmaps
- Visualize coverage by MITRE ATT&CK category
- Identify critical gaps per vendor
- Prioritize based on your context

### 🔍 Vendor Deep Dive
- Attack-level detection analysis
- Category coverage breakdown
- Performance across contexts

### 📈 BI Dashboards (Metabase)
- Executive-level reporting
- Trend analysis over time
- Custom SQL queries

## 🧠 Core Principles

### Human-Governed Architecture
```
✅ Human defines scoring rules
✅ Human sets context weights
✅ Human interprets results
❌ NO black-box AI scoring
❌ NO autonomous decisions
❌ NO unexplainable algorithms
```

### Single Source of Truth
All data lives in PostgreSQL. No duplicated logic. No stale caches. One version of truth.

### Architectural Evolution
The platform architecture, data model, and scoring mechanisms are intentionally designed to evolve.

All structural changes, scoring adjustments, and model extensions are:
- **Defined and validated by a human architect**
- **Versioned and auditable**
- **Subject to continuous refinement** as new contexts, threats, and validation criteria emerge

This project does not assume a fixed or final architecture. **Structural adaptability under human governance is a core design requirement.**

### Scoring Philosophy
Scoring within BenchmarX is intentionally:
- **Rule-based**
- **Deterministic**
- **Transparent**
- **Easy to inspect and modify**

The scoring logic is **not designed to be mathematically optimal or predictive**.

Its purpose is to:
- Make trade-offs explicit
- Enable human review
- Support reasoning and discussion

**Auditability and explainability are prioritized over algorithmic complexity.**

### Advisory Recommendations (Non-Core)
The platform may optionally generate recommendations or insights as advisory outputs.

These recommendations:
- Are **strictly non-binding**
- **Never modify core data or scoring logic**
- Are **clearly separated** from the authoritative scoring results
- Require **explicit human review and validation**

At no point are recommendations applied automatically or treated as a source of truth.

### Explainable by Design
Every score includes:
- Detection state breakdown (ACTIVE/DYNAMIC/NO_EVID)
- Context weight impact
- Calculation metadata (JSON)
- Complete audit trail

## 📊 Example Use Cases

### Financial Institution
```python
Context: "Finance - Enterprise"
High Priority:
  - Credential Access (3.0x)
  - Lateral Movement (2.5x)
  - Ransomware (2.0x)

Result: Rankings optimized for financial sector threats
```

### Healthcare Provider
```python
Context: "Healthcare - Medium"
High Priority:
  - Ransomware/Impact (3.5x)
  - Initial Access (2.0x)
  - Data Protection (1.5x)

Result: Patient care continuity prioritized
```

### SMB Manufacturer
```python
Context: "Manufacturing - Small"
High Priority:
  - Ransomware/Impact (4.0x)
  - Production Downtime Prevention

Result: Business continuity focused
```

## 🗂️ Project Structure

```
BenchmarX/
├── sql/                          # Database layer
│   ├── 01_schema.sql             # Core schema
│   ├── 02_seed_data.sql          # Sample data
│   └── 03_scoring_functions.sql  # Scoring logic
├── streamlit/                    # Simulation layer
│   ├── app.py                    # Main application
│   ├── database.py               # DB manager
│   ├── scoring.py                # Scoring engine
│   └── requirements.txt
├── metabase/                     # BI layer
│   ├── queries.md                # Pre-defined queries
│   └── setup_guide.md
├── docs/
│   ├── architecture.md           # System design
│   ├── quickstart.md             # Setup guide
│   └── deployment.md
└── scripts/                      # Automation
    ├── setup_database.sh
    └── start_streamlit.sh
```

## 🔧 Technology Stack

- **Database**: PostgreSQL 14+ (hosted on Neon)
- **Backend**: Python 3.9+ with psycopg2
- **Frontend**: Streamlit for interactive UI
- **BI**: Metabase for dashboards and reporting
- **Visualization**: Plotly for charts
- **Version Control**: Git

## 📖 Documentation

- **[Quick Start Guide](docs/quickstart.md)** - Get up and running in 15 minutes
- **[Architecture](docs/architecture.md)** - System design and principles
- **[Metabase Setup](metabase/setup_guide.md)** - Configure BI dashboards
- **[SQL Queries](metabase/queries.md)** - Pre-built BI queries

## 🚧 Roadmap

### Phase 1: MVP (Current)
- [x] Core database schema
- [x] Scoring engine
- [x] Streamlit application
- [x] Metabase queries
- [x] Documentation

### Phase 2: Enhancement
- [ ] User authentication
- [ ] API endpoints
- [ ] Automated test result import
- [ ] Custom scoring rule builder

### Phase 3: Scale
- [ ] Multi-tenant support
- [ ] Advanced reporting (PDF)
- [ ] Real-time notifications
- [ ] SIEM/SOAR integrations

### Phase 4: Community
- [ ] Vendor marketplace
- [ ] Community contexts
- [ ] Certification tracking
- [ ] Trend analysis

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

### Development Setup
```bash
# Clone and setup
git clone https://github.com/B10sp4rt4n/BenchmarX.git
cd BenchmarX

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r streamlit/requirements.txt
```

## 🤖 AI Usage Policy

BenchmarX may leverage AI-assisted tools (e.g., GitHub Copilot, LLMs) exclusively as productivity and support mechanisms.

### AI Tools MAY:
- ✅ Assist in code generation
- ✅ Suggest refactors or improvements
- ✅ Help draft documentation or explanations
- ✅ Provide debugging support

### AI Tools MUST NEVER:
- ❌ Define or alter core scoring logic autonomously
- ❌ Act as a source of truth
- ❌ Make or apply decisions
- ❌ Modify data without explicit human approval
- ❌ Become part of the decision engine

**All authoritative logic, structure, and decisions remain under direct human control.**

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Independent Test Labs**: AVLab and others for certification data
- **MITRE ATT&CK**: Framework for attack categorization
- **Neon**: Serverless PostgreSQL hosting
- **Streamlit**: Rapid app development framework
- **Metabase**: Open-source BI platform

## 📧 Contact

- **Author**: B10sp4rt4n
- **GitHub**: [@B10sp4rt4n](https://github.com/B10sp4rt4n)
- **Project**: [BenchmarX](https://github.com/B10sp4rt4n/BenchmarX)

## ⚖️ Disclaimer

BenchmarX is a decision support tool designed to augment human judgment, not replace it. All scoring logic is transparent and configurable. Users are responsible for validating results and making final procurement decisions.

**All outputs generated by BenchmarX are intended to support informed human decision-making.**

**Final responsibility for interpretation, validation, and action always rests with the human operator.**

**This tool does not:**
- Replace vendor evaluations
- Guarantee product performance
- Make autonomous purchasing decisions
- Use black-box AI algorithms

**This tool does:**
- Organize certification data
- Apply your business context
- Enable what-if analysis
- Provide explainable rankings

---

**Built with 🧠 Human Intelligence | Assisted by 🤖 AI Tools | Governed by 👥 Human Decisions**

*"In a world of complexity, clarity is power."*