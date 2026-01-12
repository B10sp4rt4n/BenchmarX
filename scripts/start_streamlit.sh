#!/bin/bash

# BenchmarX - Start Streamlit Application

set -e

echo "🚀 Starting BenchmarX Streamlit Application"
echo "=========================================="

# Check if .streamlit/secrets.toml exists
if [ ! -f "streamlit/.streamlit/secrets.toml" ]; then
    echo "⚠️  Warning: .streamlit/secrets.toml not found"
    echo "Creating from example..."
    mkdir -p streamlit/.streamlit
    cp streamlit/.streamlit/secrets.toml.example streamlit/.streamlit/secrets.toml
    echo ""
    echo "❗ Please edit streamlit/.streamlit/secrets.toml with your DATABASE_URL"
    echo ""
    read -p "Press Enter once you've configured the database connection..."
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -q -r streamlit/requirements.txt

# Start Streamlit
echo ""
echo "✅ Starting Streamlit on http://localhost:8501"
echo ""
cd streamlit && streamlit run app.py
