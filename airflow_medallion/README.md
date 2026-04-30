# Airflow — dbt Run & Test Pipeline

Orchestrates **dbt Silver + Gold model runs and tests** against an already-loaded Snowflake Bronze layer.

- **Apache Airflow 2.9** (Docker Compose, LocalExecutor)
- **dbt-snowflake 1.8** (BashOperator, dbt CLI)
- **Snowflake** (Bronze data already loaded)

---

## Project layout

```
airflow_medallion/
├── docker-compose.yml              # Airflow + Postgres services
├── Dockerfile                      # Airflow image + dbt-snowflake
├── .env.example                    # Copy to .env — fill in credentials
├── dags/
│   └── sales_dwh_pipeline.py       # DAG: deps → Silver → Gold → tests
└── config/
    └── dbt_profiles/
        └── profiles.yml            # dbt Snowflake connection
```

Place this folder **next to** your `sales_dwh/` dbt project:

```
Medallion-Architecture-Project/
├── airflow_medallion/     ← this folder
└── sales_dwh/             ← your existing dbt project
```

---

## Quick start

### 1. Set up credentials

```bash
cp .env.example .env
# Edit .env with your Snowflake account, user, and password
```

### 2. Build and start

```bash
docker compose build
docker compose up -d
```

Airflow UI → http://localhost:8080  (admin / admin)

### 3. Trigger the DAG

In the UI: find `sales_dwh_pipeline`, toggle it **ON**, click **Trigger DAG**.

---

## DAG structure

```
dbt_deps
   │
   ▼
dbt_silver/
   └── dbt_run_silver          # dbt run --select staging
   │
   ▼
dbt_gold/
   ├── dbt_run_dimensions      # dim_customers, dim_products
   └── dbt_run_facts           # fact_sales  (after dims)
   │
   ▼
dbt_tests/
   ├── dbt_test_silver         # tests on staging models
   └── dbt_test_gold           # unique + not_null on dims/facts
```

---

## Useful commands

```bash
# Trigger DAG from CLI
docker compose exec airflow-webserver \
  airflow dags trigger sales_dwh_pipeline

# Run dbt manually inside container
docker compose exec airflow-webserver bash
dbt run --project-dir /opt/airflow/dbt/sales_dwh \
        --profiles-dir /opt/airflow/dbt/profiles

# Stop
docker compose down

# Stop and wipe Postgres metadata
docker compose down -v
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `dbt: command not found` | Rebuild: `docker compose build --no-cache` |
| `could not find profile` | Check `config/dbt_profiles/profiles.yml` exists and volume is mounted |
| dbt can't connect to Snowflake | Verify `.env` credentials; check `SNOWFLAKE_ACCOUNT` format (`xy12345.us-east-1`) |
| Tests fail on Silver | Check `stg_erp_categories` has column aliases — bare `select *` can break if Bronze schema changes |
