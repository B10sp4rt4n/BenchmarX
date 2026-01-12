#!/bin/bash

# BenchmarX - Neon Database Setup Script
set -e

echo "🚀 Setting up BenchmarX database on Neon..."

# Connection details
export PGPASSWORD='npg_2FGMBV3cTDJL'
HOST='ep-sweet-cake-aha88oyj-pooler.c-3.us-east-1.aws.neon.tech'
USER='neondb_owner'
DB='neondb'

# Test connection
echo "📡 Testing connection..."
psql -h $HOST -U $USER -d $DB -c "SELECT version();" || {
    echo "❌ Connection failed!"
    exit 1
}

echo "✅ Connection successful!"
echo ""

# Execute SQL scripts
echo "📊 Creating schema (01_schema.sql)..."
psql -h $HOST -U $USER -d $DB -f sql/01_schema.sql

echo "✅ Schema created!"
echo ""

echo "📝 Loading seed data (02_seed_data.sql)..."
psql -h $HOST -U $USER -d $DB -f sql/02_seed_data.sql

echo "✅ Seed data loaded!"
echo ""

echo "🧮 Creating scoring functions (03_scoring_functions.sql)..."
psql -h $HOST -U $USER -d $DB -f sql/03_scoring_functions.sql

echo "✅ Scoring functions created!"
echo ""

echo "📦 Adding benchmark versioning (04_benchmark_versioning.sql)..."
psql -h $HOST -U $USER -d $DB -f sql/04_benchmark_versioning.sql

echo "✅ Benchmark versioning added!"
echo ""

echo "🔄 Creating benchmark-aware functions (05_benchmark_scoring_functions.sql)..."
psql -h $HOST -U $USER -d $DB -f sql/05_benchmark_scoring_functions.sql

echo "✅ Benchmark functions created!"
echo ""

echo "📊 Loading sample benchmark data (05_benchmark_sample_data.sql)..."
psql -h $HOST -U $USER -d $DB -f sql/05_benchmark_sample_data.sql

echo "✅ Sample data loaded!"
echo ""

# Verify setup
echo "🔍 Verifying setup..."
echo ""
echo "Vendors:"
psql -h $HOST -U $USER -d $DB -c "SELECT COUNT(*) FROM vendors;"
echo ""
echo "Attacks:"
psql -h $HOST -U $USER -d $DB -c "SELECT COUNT(*) FROM attacks;"
echo ""
echo "Contexts:"
psql -h $HOST -U $USER -d $DB -c "SELECT COUNT(*) FROM context_profiles;"
echo ""
echo "Benchmarks:"
psql -h $HOST -U $USER -d $DB -c "SELECT name, report_date, is_active FROM benchmarks;"
echo ""

echo "🎉 Database setup complete!"
echo ""
echo "Next steps:"
echo "1. Reload your Streamlit app (it should now connect successfully)"
echo "2. Explore the Dashboard"
echo "3. Manage benchmarks in the Benchmarks page"
echo ""
