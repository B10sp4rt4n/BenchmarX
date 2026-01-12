# Metabase Setup Guide for BenchmarX

## Overview
Metabase serves as the Business Intelligence layer for BenchmarX, providing interactive dashboards and reports. It connects directly to your Neon PostgreSQL database in read-only mode.

## Prerequisites
- Neon PostgreSQL database with BenchmarX schema deployed
- Metabase instance (cloud or self-hosted)
- Database connection credentials

## Setup Steps

### 1. Install Metabase

#### Option A: Cloud (Recommended)
1. Go to [metabase.com](https://www.metabase.com/)
2. Sign up for a cloud account
3. Follow the setup wizard

#### Option B: Self-Hosted (Docker)
```bash
docker run -d -p 3000:3000 \
  -e "MB_DB_TYPE=postgres" \
  -e "MB_DB_DBNAME=metabase" \
  -e "MB_DB_PORT=5432" \
  -e "MB_DB_USER=metabase" \
  -e "MB_DB_PASS=your_password" \
  -e "MB_DB_HOST=your_postgres_host" \
  --name metabase metabase/metabase
```

### 2. Connect to Neon Database

1. In Metabase, go to **Settings** → **Admin** → **Databases**
2. Click **Add Database**
3. Configure connection:
   - **Database type**: PostgreSQL
   - **Name**: BenchmarX
   - **Host**: Your Neon host (e.g., `ep-xxxxx.region.aws.neon.tech`)
   - **Port**: `5432`
   - **Database name**: `benchmarx`
   - **Username**: Your database user
   - **Password**: Your database password
   - **SSL**: Enable (required for Neon)
   - **SSL Mode**: `require`

4. Click **Save**
5. Verify connection is successful

### 3. Configure Read-Only Access (Recommended)

Create a read-only user in your Neon database:

```sql
-- Create read-only user for Metabase
CREATE USER metabase_readonly WITH PASSWORD 'secure_password_here';

-- Grant connection to database
GRANT CONNECT ON DATABASE benchmarx TO metabase_readonly;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO metabase_readonly;

-- Grant SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO metabase_readonly;

-- Grant SELECT on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO metabase_readonly;

-- Grant EXECUTE on functions (for viewing results only)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO metabase_readonly;
```

Update Metabase connection to use `metabase_readonly` user.

### 4. Import Pre-Defined Queries

Use the queries from [queries.md](./queries.md) to create:

1. **Questions** (saved queries)
   - Go to **New** → **Question** → **Native query**
   - Paste SQL from queries.md
   - Save with descriptive name

2. **Collections** (organize queries)
   - Create collections:
     - "Rankings"
     - "Coverage Analysis"
     - "Risk Assessment"
     - "Trends"
     - "Executive Reports"

### 5. Create Dashboards

#### Dashboard 1: Executive Overview
1. Create new dashboard: "Executive Overview"
2. Add cards:
   - KPI: Total Vendors
   - KPI: Total Contexts
   - KPI: Total Attacks
   - Chart: Top 5 Vendors (Query #10)
   - Chart: Detection Distribution (Query #5)

#### Dashboard 2: Context Rankings
1. Create new dashboard: "Context-Specific Rankings"
2. Add filter: Context selector
3. Add cards:
   - Table: Vendor Rankings (Query #1)
   - Chart: Score Comparison (Query #1)
   - Chart: Category Heatmap (Query #2)

#### Dashboard 3: Vendor Analysis
1. Create new dashboard: "Vendor Deep Dive"
2. Add filter: Vendor selector
3. Add cards:
   - Table: Category Coverage (Query #2)
   - Chart: Detection Breakdown (Query #5)
   - Chart: Context Performance (Query #7)
   - Table: Security Gaps (Query #6)

#### Dashboard 4: Risk Heatmap
1. Create new dashboard: "Risk Analysis"
2. Add cards:
   - Heatmap: Category Coverage (Query #2)
   - Table: Critical Gaps (Query #6)
   - Chart: Gap Distribution (Query #6)

### 6. Configure Dashboard Filters

Add parameterized filters to make dashboards interactive:

1. **Context Filter**
   ```sql
   WHERE context_profile_id = {{context_id}}
   ```

2. **Vendor Filter**
   ```sql
   WHERE vendor_id = {{vendor_id}}
   ```

3. **Date Range Filter**
   ```sql
   WHERE created_at BETWEEN {{start_date}} AND {{end_date}}
   ```

### 7. Set Up Permissions

1. Go to **Settings** → **Admin** → **Permissions**
2. Create groups:
   - **Executives**: View-only access to Executive dashboards
   - **Security Team**: Full access to all dashboards
   - **Analysts**: Access to analysis dashboards

3. Configure data access:
   - All groups: **View data** only
   - No groups: **Edit data** (maintain read-only)

### 8. Schedule Reports (Optional)

1. Open dashboard
2. Click **Share** → **Schedule email**
3. Configure:
   - Recipients
   - Frequency (daily, weekly, monthly)
   - Format (PDF, PNG)

### 9. Set Up Alerts (Optional)

Create alerts for important metrics:

1. Go to question/chart
2. Click **•••** → **Get alerts**
3. Configure:
   - Condition (e.g., "when score drops below 80%")
   - Recipients
   - Frequency

## Best Practices

### 1. Naming Conventions
- **Questions**: Descriptive names (e.g., "Vendor Rankings by Context")
- **Dashboards**: Clear purpose (e.g., "Executive Overview")
- **Collections**: Logical grouping (e.g., "Risk Assessment")

### 2. Performance Optimization
- Use materialized views for complex queries
- Add indexes for frequently filtered columns
- Schedule dashboard refreshes during off-peak hours

### 3. Documentation
- Add descriptions to questions and dashboards
- Document filter parameters
- Include context in dashboard titles

### 4. Governance
- Maintain read-only access
- Regular permission audits
- Track dashboard usage

## Troubleshooting

### Connection Issues
- Verify Neon connection string
- Check SSL settings (must be enabled)
- Verify firewall rules allow Metabase IP

### Query Performance
- Check database indexes
- Review query execution plans
- Consider materialized views

### Data Not Showing
- Verify data exists in database
- Check filter parameters
- Review permissions

## Security Considerations

1. **Read-Only Access**: Never grant write permissions to Metabase
2. **SSL/TLS**: Always use encrypted connections
3. **Audit Logging**: Track who views what dashboards
4. **Data Masking**: Consider masking sensitive data if needed
5. **Access Control**: Use granular permissions

## Maintenance

### Regular Tasks
- **Weekly**: Review dashboard performance
- **Monthly**: Audit user permissions
- **Quarterly**: Archive unused dashboards
- **Annually**: Review and update visualizations

### Backup
- Export dashboard configurations regularly
- Document custom SQL queries
- Maintain version control for queries

## Integration with Streamlit

BenchmarX uses both Metabase and Streamlit:

- **Metabase**: Business Intelligence, reporting, executive views
- **Streamlit**: Simulation, what-if analysis, context management

Keep them complementary:
- Metabase shows "what is"
- Streamlit explores "what if"

## Support

For Metabase-specific issues:
- Documentation: https://www.metabase.com/docs/
- Community: https://discourse.metabase.com/

For BenchmarX-specific issues:
- Check SQL queries in [queries.md](./queries.md)
- Review database schema in [sql/01_schema.sql](../sql/01_schema.sql)
