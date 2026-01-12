#!/bin/bash

# BenchmarX - Database Setup Script
# Deploys schema, seed data, and functions to PostgreSQL/Neon

set -e  # Exit on error

echo "🚀 BenchmarX Database Setup"
echo "================================"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Environment variables loaded"
else
    echo "❌ .env file not found. Please create one from .env.example"
    exit 1
fi

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set in .env file"
    exit 1
fi

echo ""
echo "📊 Database: ${DATABASE_URL%%\?*}"  # Hide password in output
echo ""

# Function to run SQL file
run_sql_file() {
    local file=$1
    local description=$2
    echo "⏳ $description..."
    if psql "$DATABASE_URL" -f "$file" > /dev/null 2>&1; then
        echo "✅ $description - Complete"
    else
        echo "❌ $description - Failed"
        exit 1
    fi
}

# Deploy schema
run_sql_file "sql/01_schema.sql" "Creating database schema"

# Deploy seed data
read -p "Load seed data? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_sql_file "sql/02_seed_data.sql" "Loading seed data"
fi

# Deploy scoring functions
run_sql_file "sql/03_scoring_functions.sql" "Creating scoring functions"

echo ""
echo "🎉 Database setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure Streamlit: cd streamlit && cp .streamlit/secrets.toml.example .streamlit/secrets.toml"
echo "2. Add your DATABASE_URL to .streamlit/secrets.toml"
echo "3. Start Streamlit: streamlit run app.py"
echo "4. Configure Metabase using metabase/setup_guide.md"
echo ""
