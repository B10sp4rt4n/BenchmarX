# BenchmarX - Quick Start Guide

## Overview
BenchmarX is a dynamic, context-aware benchmark platform for EDR/XDR solutions. This guide will help you get started quickly.

## Prerequisites

- Python 3.9+
- PostgreSQL 14+ or Neon account
- Git

## Installation Steps

### 1. Clone Repository
```bash
git clone https://github.com/B10sp4rt4n/BenchmarX.git
cd BenchmarX
```

### 2. Set Up Database

#### Option A: Using Neon (Recommended)
1. Create account at [neon.tech](https://neon.tech)
2. Create new project named "BenchmarX"
3. Copy connection string

#### Option B: Local PostgreSQL
```bash
createdb benchmarx
```

### 3. Configure Environment
```bash
# Copy example environment file
cp .env.example .env

# Edit .env and add your database connection string
nano .env
```

Update `DATABASE_URL`:
```
DATABASE_URL=postgresql://user:password@host:5432/benchmarx?sslmode=require
```

### 4. Deploy Database Schema
```bash
./scripts/setup_database.sh
```

This will:
- Create all tables, views, and functions
- Optionally load sample data
- Validate the setup

### 5. Configure Streamlit
```bash
cd streamlit
cp .streamlit/secrets.toml.example .streamlit/secrets.toml
nano .streamlit/secrets.toml
```

Add your `DATABASE_URL` to secrets.toml.

### 6. Start Streamlit Application
```bash
# From project root
./scripts/start_streamlit.sh
```

Or manually:
```bash
cd streamlit
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
streamlit run app.py
```

### 7. Access the Application
Open your browser to: http://localhost:8501

## First Steps

### 1. Explore Dashboard
- View system overview
- Check vendor count and attack coverage
- Review scoring rule configuration

### 2. Create Your First Context
1. Navigate to "⚙️ Context Manager"
2. Click "Create Context" tab
3. Fill in:
   - Name: e.g., "My Organization"
   - Industry: Select your industry
   - Company Size: Small/Medium/Enterprise
   - Security Maturity: Basic/Intermediate/Advanced
4. Click "Create Context"

### 3. Set Context Weights
1. Still in Context Manager
2. View your newly created context
3. Add weights for critical attack categories
4. Provide rationale for each weight

### 4. View Rankings
1. Navigate to "📊 Rankings"
2. Select your context
3. View vendor rankings tailored to your context

### 5. Run What-If Simulation
1. Navigate to "🧪 What-If Simulator"
2. Select a base context
3. Adjust category weights
4. Click "Run Simulation"
5. Compare results with original rankings

## Understanding the Data

### Detection States
- **ACTIVE**: Proactive detection before malicious behavior
- **DYNAMIC**: Detection after observing behavior
- **NO_EVID**: No evidence of detection

### Scoring Logic (Default v1.0)
- ACTIVE: 10 points
- DYNAMIC: 5 points
- NO_EVID: 0 points

Points are multiplied by context weights to create context-aware scores.

### Context Weights
- Default weight: 1.0 (neutral)
- Higher weight (e.g., 3.0): Category is 3x more important
- Lower weight (e.g., 0.5): Category is less critical

## Optional: Set Up Metabase

### 1. Install Metabase
```bash
docker run -d -p 3000:3000 \
  --name metabase \
  metabase/metabase
```

### 2. Configure Connection
1. Open http://localhost:3000
2. Complete setup wizard
3. Add BenchmarX database connection
4. Use read-only credentials (see [metabase/setup_guide.md](../metabase/setup_guide.md))

### 3. Import Queries
- Copy queries from [metabase/queries.md](../metabase/queries.md)
- Create dashboards following [metabase/setup_guide.md](../metabase/setup_guide.md)

## Project Structure

```
BenchmarX/
├── sql/                    # Database schema and functions
│   ├── 01_schema.sql       # Core database schema
│   ├── 02_seed_data.sql    # Sample data
│   └── 03_scoring_functions.sql  # Scoring logic
├── streamlit/              # Streamlit application
│   ├── app.py              # Main application
│   ├── database.py         # Database manager
│   ├── scoring.py          # Scoring engine
│   └── requirements.txt    # Python dependencies
├── metabase/               # Metabase configuration
│   ├── queries.md          # Pre-defined SQL queries
│   └── setup_guide.md      # Setup instructions
├── docs/                   # Documentation
│   ├── architecture.md     # System architecture
│   ├── quickstart.md       # This file
│   └── deployment.md       # Deployment guide
├── scripts/                # Utility scripts
│   ├── setup_database.sh   # Database setup
│   └── start_streamlit.sh  # Start Streamlit
├── .env.example            # Environment template
├── .gitignore              # Git ignore rules
├── requirements.txt        # Root dependencies
└── README.md               # Project overview
```

## Troubleshooting

### Database Connection Issues
```bash
# Test connection
psql "$DATABASE_URL" -c "SELECT version();"
```

If this fails:
- Check connection string format
- Verify database exists
- Check firewall/network access
- For Neon: Ensure SSL is enabled

### Streamlit Not Starting
```bash
# Check if port 8501 is available
lsof -i :8501

# Try different port
streamlit run app.py --server.port 8502
```

### No Data Showing
```bash
# Verify data exists
psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM vendors;"

# Re-run seed data
psql "$DATABASE_URL" -f sql/02_seed_data.sql
```

### Import Errors
```bash
# Reinstall dependencies
pip install --force-reinstall -r streamlit/requirements.txt
```

## Next Steps

### Add Real Data
1. Replace sample vendors with your evaluation targets
2. Import actual test results from AVLab or similar
3. Create contexts matching your organization's needs
4. Define weights based on your risk priorities

### Customize Scoring
1. Review default scoring rule (v1.0)
2. Create new scoring rule if needed
3. Document rationale for scoring changes
4. Test with simulations before activating

### Share with Team
1. Deploy to Streamlit Cloud (free tier available)
2. Set up Metabase for executives
3. Create role-based access (future feature)
4. Schedule regular reports

## Support

### Documentation
- [Architecture](./architecture.md) - System design and principles
- [Deployment](./deployment.md) - Production deployment guide
- [Metabase Setup](../metabase/setup_guide.md) - BI configuration

### Community
- GitHub Issues: Report bugs and request features
- Discussions: Ask questions and share ideas

### Development
- SQL Schema: [sql/01_schema.sql](../sql/01_schema.sql)
- Streamlit App: [streamlit/app.py](../streamlit/app.py)
- Scoring Logic: [streamlit/scoring.py](../streamlit/scoring.py)

## Key Principles to Remember

1. **Human-Governed**: All scoring logic is human-defined
2. **Context-Aware**: Rankings change based on your business context
3. **Explainable**: Every score can be traced and explained
4. **Deterministic**: Same inputs always produce same outputs
5. **Auditable**: Complete history in database

## Example Use Cases

### Use Case 1: Selecting EDR for Financial Institution
1. Create context: "Finance - Enterprise"
2. Set high weights for:
   - Credential Access (3.0)
   - Lateral Movement (2.5)
   - Ransomware/Impact (2.0)
3. View rankings optimized for financial sector
4. Export comparison report

### Use Case 2: Budget-Constrained SMB
1. Create context: "Small Business - Basic Security"
2. Set high weights for:
   - Ransomware/Impact (4.0)
   - Initial Access (2.0)
3. Compare top 3 vendors
4. Run what-if: "What if we mature to Intermediate?"

### Use Case 3: Healthcare Compliance
1. Create context: "Healthcare - Medium"
2. Set weights based on HIPAA priorities:
   - Impact (3.5)
   - Data Exfiltration (3.0)
   - Initial Access (2.0)
3. Generate compliance-focused report
4. Share with CISO and board

---

**Ready to start?** Follow the installation steps above, and you'll have BenchmarX running in ~15 minutes! 🚀
