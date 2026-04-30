"""
validate_bronze.py
──────────────────
Queries each Bronze table and raises an error if any table is empty.
Called by the validate_bronze_row_counts task inside the DAG.
"""

import os
import sys
import logging
import snowflake.connector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

BRONZE_TABLES = [
    "BRONZE.CRM_CUST_INFO",
    "BRONZE.CRM_PRD_INFO",
    "BRONZE.CRM_SALES_DETAILS",
    "BRONZE.ERP_LOC_A101",
    "BRONZE.ERP_CUST_AZ12",
    "BRONZE.ERP_PX_CAT_G1V2",
]


def main() -> None:
    conn = snowflake.connector.connect(
        account   = os.environ["SNOWFLAKE_ACCOUNT"],
        user      = os.environ["SNOWFLAKE_USER"],
        password  = os.environ["SNOWFLAKE_PASSWORD"],
        role      = os.getenv("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
        warehouse = os.getenv("SNOWFLAKE_WAREHOUSE", "SALES_DWH_WH"),
        database  = os.getenv("SNOWFLAKE_DATABASE", "SALES_DATA_WAREHOUSE"),
    )
    cs = conn.cursor()
    failures = []

    try:
        for table in BRONZE_TABLES:
            cs.execute(f"SELECT COUNT(*) FROM {table}")
            count = cs.fetchone()[0]
            log.info("%-35s  rows: %d", table, count)
            if count == 0:
                failures.append(table)
    finally:
        cs.close()
        conn.close()

    if failures:
        log.error("Empty Bronze tables detected: %s", failures)
        sys.exit(1)

    log.info("All Bronze tables have data. Validation passed.")


if __name__ == "__main__":
    main()
