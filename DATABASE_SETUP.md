# BenchmarX - Configuración de Base de Datos

## 🚀 Inicio Rápido

Para ejecutar BenchmarX necesitas una base de datos PostgreSQL. Aquí tienes las opciones:

## Opción 1: Neon (Recomendado - Gratis y en la nube) ☁️

**Neon es un PostgreSQL serverless gratuito, perfecto para BenchmarX:**

1. **Crear cuenta en Neon:**
   - Ve a https://console.neon.tech
   - Regístrate gratis (no requiere tarjeta)

2. **Crear proyecto:**
   - Click en "Create Project"
   - Nombre: `benchmarx`
   - Región: Elige la más cercana
   - PostgreSQL version: 14 o superior

3. **Obtener connection string:**
   - En el dashboard, copia el "Connection String"
   - Se verá algo así: `postgresql://user:pass@ep-xxxxx.region.aws.neon.tech/benchmarx?sslmode=require`

4. **Configurar BenchmarX:**
   ```bash
   # Edita el archivo de secrets
   nano /workspaces/BenchmarX/streamlit/.streamlit/secrets.toml
   
   # Pega tu connection string
   DATABASE_URL = "postgresql://user:pass@ep-xxxxx.region.aws.neon.tech/benchmarx?sslmode=require"
   ```

5. **Configurar el schema:**
   ```bash
   cd /workspaces/BenchmarX
   
   # Ejecuta los scripts SQL en orden
   psql "YOUR_CONNECTION_STRING" -f sql/01_schema.sql
   psql "YOUR_CONNECTION_STRING" -f sql/02_seed_data.sql
   psql "YOUR_CONNECTION_STRING" -f sql/03_scoring_functions.sql
   psql "YOUR_CONNECTION_STRING" -f sql/04_benchmark_versioning.sql
   psql "YOUR_CONNECTION_STRING" -f sql/05_benchmark_scoring_functions.sql
   psql "YOUR_CONNECTION_STRING" -f sql/05_benchmark_sample_data.sql
   ```

6. **Reiniciar Streamlit:**
   ```bash
   # Detén el proceso actual (Ctrl+C en el terminal)
   cd /workspaces/BenchmarX/streamlit
   streamlit run app.py
   ```

## Opción 2: PostgreSQL Local 💻

Si prefieres una base de datos local:

1. **Instalar PostgreSQL:**
   ```bash
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   ```

2. **Iniciar servicio:**
   ```bash
   sudo service postgresql start
   ```

3. **Crear base de datos:**
   ```bash
   sudo -u postgres psql
   CREATE DATABASE benchmarx;
   CREATE USER benchmarx_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE benchmarx TO benchmarx_user;
   \q
   ```

4. **Configurar secrets.toml:**
   ```toml
   DATABASE_URL = "postgresql://benchmarx_user:your_password@localhost:5432/benchmarx"
   ```

5. **Configurar schema:** (igual que Opción 1, paso 5)

## Opción 3: Script Automatizado 🤖

Hemos incluido un script que facilita el setup:

```bash
cd /workspaces/BenchmarX

# 1. Configurar la variable de entorno
export DATABASE_URL="tu_connection_string_aqui"

# O crear archivo .env
echo 'DATABASE_URL="tu_connection_string_aqui"' > .env

# 2. Ejecutar el script de setup
chmod +x scripts/setup_database.sh
./scripts/setup_database.sh
```

## ✅ Verificar Configuración

Para verificar que todo está funcionando:

```bash
# Test de conexión
psql "YOUR_CONNECTION_STRING" -c "SELECT COUNT(*) FROM vendors;"

# Debería retornar el número de vendors en la DB
```

## 🔧 Troubleshooting

### Error: "No such file or directory"
- **Causa:** No hay DATABASE_URL configurado
- **Solución:** Edita `streamlit/.streamlit/secrets.toml` con tu connection string

### Error: "Connection refused"
- **Causa:** PostgreSQL no está corriendo o la URL es incorrecta
- **Solución:** Verifica que PostgreSQL esté activo o que el connection string sea correcto

### Error: "relation does not exist"
- **Causa:** No has ejecutado los scripts SQL
- **Solución:** Ejecuta los archivos SQL en orden (ver Opción 1, paso 5)

## 📊 Datos de Ejemplo

Los scripts incluyen datos de ejemplo:
- 5 vendors (CrowdStrike, Microsoft, SentinelOne, Palo Alto, Trend Micro)
- 25 ataques MITRE ATT&CK
- 5 contextos de negocio
- 2 benchmarks de ejemplo (Q4 2024, Q1 2025)

## 🎯 Próximos Pasos

Una vez configurada la base de datos:

1. **Explorar el Dashboard:** Vista general del sistema
2. **Gestionar Benchmarks:** Importar nuevos reportes de test labs
3. **Ver Rankings:** Rankings contextualizados por industria
4. **Simulaciones:** Experimentos "what-if" con pesos
5. **Metabase:** Conectar tu instancia de Metabase (ver `/metabase/setup_guide.md`)

## 🆘 Soporte

- **Documentación completa:** `/docs/`
- **Arquitectura:** `/docs/architecture.md`
- **Governance:** `/docs/governance.md`
- **Issues:** https://github.com/B10sp4rt4n/BenchmarX/issues
