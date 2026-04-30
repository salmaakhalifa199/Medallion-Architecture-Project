"""
sales_dwh_pipeline.py
─────────────────────
Airflow DAG — dbt run + test only.
Bronze data is already loaded in Snowflake, so this DAG simply
refreshes the Silver and Gold dbt models then validates them.

    [dbt deps]  →  [dbt run Silver]  →  [dbt run Gold]  →  [dbt test]

Schedule : daily at 02:00 UTC
Retries  : 1 per task, 5-minute delay
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup

# ──────────────────────────────────────────────────────────────
# Paths (resolved inside the Docker container)
# ──────────────────────────────────────────────────────────────
DBT_PROJECT_DIR  = os.getenv("DBT_PROJECT_DIR",  "/opt/airflow/dbt/sales_dwh")
DBT_PROFILES_DIR = os.getenv("DBT_PROFILES_DIR", "/opt/airflow/dbt/profiles")

DBT_FLAGS = (
    f"--project-dir {DBT_PROJECT_DIR} "
    f"--profiles-dir {DBT_PROFILES_DIR} "
    "--no-use-colors"
)

# ──────────────────────────────────────────────────────────────
# Default args
# ──────────────────────────────────────────────────────────────
default_args = {
    "owner": "data-team",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

# ──────────────────────────────────────────────────────────────
# DAG
# ──────────────────────────────────────────────────────────────
with DAG(
    dag_id="sales_dwh_pipeline",
    description="dbt run + test for Silver and Gold layers (Bronze pre-loaded)",
    schedule_interval="0 2 * * *",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=["medallion", "dbt", "snowflake"],
) as dag:

    # ── 1. Install dbt packages (dbt_utils) ───────────────────
    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command=f"dbt deps {DBT_FLAGS}",
    )

    # ── 2. Run Silver staging models ──────────────────────────
    with TaskGroup("dbt_silver", tooltip="Run Silver staging models") as silver_group:

        run_silver = BashOperator(
            task_id="dbt_run_silver",
            bash_command=f"dbt run {DBT_FLAGS} --select staging",
        )

    # ── 3. Run Gold mart models ───────────────────────────────
    with TaskGroup("dbt_gold", tooltip="Run Gold mart models") as gold_group:

        run_dims = BashOperator(
            task_id="dbt_run_dimensions",
            bash_command=(
                f"dbt run {DBT_FLAGS} "
                "--select marts.gold.dim_customers marts.gold.dim_products"
            ),
        )

        run_facts = BashOperator(
            task_id="dbt_run_facts",
            bash_command=f"dbt run {DBT_FLAGS} --select marts.gold.fact_sales",
        )

        # dims must exist before fact_sales joins them
        run_dims >> run_facts

    # ── 4. Test all models ────────────────────────────────────
    with TaskGroup("dbt_tests", tooltip="Run dbt schema tests") as test_group:

        test_silver = BashOperator(
            task_id="dbt_test_silver",
            bash_command=f"dbt test {DBT_FLAGS} --select staging",
        )

        test_gold = BashOperator(
            task_id="dbt_test_gold",
            bash_command=f"dbt test {DBT_FLAGS} --select marts",
        )

        test_silver >> test_gold

    # ── Pipeline chain ────────────────────────────────────────
    dbt_deps >> silver_group >> gold_group >> test_group
