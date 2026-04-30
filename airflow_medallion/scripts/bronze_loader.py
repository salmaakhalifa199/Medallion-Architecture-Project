"""
bronze_loader.py
────────────────
Uploads local CSV files to a Snowflake internal stage and runs COPY INTO
for each Bronze table.  Called by BashOperator inside the Airflow DAG.

Usage:
    python bronze_loader.py --csv-dir /opt/airflow/data
"""

import argparse
import os
import sys
import logging

import snowflake.connector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)


# ──────────────────────────────────────────────────────────────
# Mapping: local filename  →  (Bronze table, stage path prefix)
# ──────────────────────────────────────────────────────────────
FILE_TABLE_MAP = {
    "cust_info.csv":     "BRONZE.CRM_CUST_INFO",
    "prd_info.csv":      "BRONZE.CRM_PRD_INFO",
    "sales_details.csv": "BRONZE.CRM_SALES_DETAILS",
    "loc_a101.csv":      "BRONZE.ERP_LOC_A101",
    "cust_az12.csv":     "BRONZE.ERP_CUST_AZ12",
    "px_cat_g1v2.csv":   "BRONZE.ERP_PX_CAT_G1V2",
}

STAGE      = "BRONZE.BRONZE_STAGE"
FILE_FMT   = "BRONZE.CSV_FILE_FORMAT"


def get_connection() -> snowflake.connector.SnowflakeConnection:
    """Build a Snowflake connection from environment variables."""
    required = ["SNOWFLAKE_ACCOUNT", "SNOWFLAKE_USER", "SNOWFLAKE_PASSWORD"]
    missing = [v for v in required if not os.getenv(v)]
    if missing:
        log.error("Missing env vars: %s", missing)
        sys.exit(1)

    return snowflake.connector.connect(
        account   = os.environ["SNOWFLAKE_ACCOUNT"],
        user      = os.environ["SNOWFLAKE_USER"],
        password  = os.environ["SNOWFLAKE_PASSWORD"],
        role      = os.getenv("SNOWFLAKE_ROLE", "SYSADMIN"),
        warehouse = os.getenv("SNOWFLAKE_WAREHOUSE", "SALES_DWH_WH"),
        database  = os.getenv("SNOWFLAKE_DATABASE", "SALES_DATA_WAREHOUSE"),
        schema    = "BRONZE",
    )


def upload_and_load(csv_dir: str) -> None:
    conn = get_connection()
    cs   = conn.cursor()

    try:
        cs.execute(f"USE DATABASE {os.getenv('SNOWFLAKE_DATABASE', 'SALES_DATA_WAREHOUSE')}")
        cs.execute("USE SCHEMA BRONZE")

        for filename, table in FILE_TABLE_MAP.items():
            filepath = os.path.join(csv_dir, filename)

            # ── locate file (check both source_crm and source_erp sub-dirs) ──
            if not os.path.exists(filepath):
                for subdir in ("source_crm", "source_erp"):
                    candidate = os.path.join(csv_dir, subdir, filename)
                    if os.path.exists(candidate):
                        filepath = candidate
                        break

            if not os.path.exists(filepath):
                log.warning("File not found, skipping: %s", filename)
                continue

            log.info("Uploading %s → @%s", filepath, STAGE)
            put_sql = (
                f"PUT 'file://{filepath}' @{STAGE} "
                f"AUTO_COMPRESS=TRUE OVERWRITE=TRUE"
            )
            cs.execute(put_sql)
            log.info("PUT result: %s", cs.fetchall())

            log.info("Running COPY INTO %s", table)
            copy_sql = f"""
                COPY INTO {table}
                FROM @{STAGE}/{filename}.gz
                FILE_FORMAT = (FORMAT_NAME = {FILE_FMT})
                PURGE = FALSE
                ON_ERROR = CONTINUE
            """
            cs.execute(copy_sql)
            rows = cs.fetchall()
            log.info("COPY result for %s: %s", table, rows)

        log.info("Bronze load complete.")

    except Exception as exc:
        log.error("Bronze load failed: %s", exc)
        raise
    finally:
        cs.close()
        conn.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Load CSVs into Snowflake Bronze layer")
    parser.add_argument(
        "--csv-dir",
        default=os.getenv("CSV_SOURCE_DIR", "/opt/airflow/data"),
        help="Directory containing the source CSV files",
    )
    args = parser.parse_args()
    upload_and_load(args.csv_dir)
