-- =========================================================
-- SALES DATA WAREHOUSE - BRONZE LAYER (SNOWFLAKE VERSION)
-- =========================================================
-- This script:
-- 1. Create schema SALES_DWH_WH;
-- 2. Creates Database
-- 3. Creates Schemas
-- 4. Creates Bronze Tables
-- 5. Creates Internal Stage
-- 6. Loads CSV Files using COPY INTO
-- =========================================================


-- =========================================================
-- STEP 1: CREATE warehouse
-- =========================================================

CREATE OR REPLACE WAREHOUSE SALES_DWH_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;


-- =========================================================
-- STEP 2: CREATE DATABASE
-- =========================================================

CREATE OR REPLACE DATABASE SALES_DATA_WAREHOUSE;

USE DATABASE SALES_DATA_WAREHOUSE;


-- =========================================================
-- STEP 3: CREATE SCHEMAS
-- =========================================================

CREATE OR REPLACE SCHEMA BRONZE;
CREATE OR REPLACE SCHEMA SILVER;
CREATE OR REPLACE SCHEMA GOLD;


-- =========================================================
-- STEP 4: CREATE BRONZE TABLES
-- =========================================================

-- =====================================
-- BRONZE.CRM_CUST_INFO
-- =====================================

CREATE OR REPLACE TABLE BRONZE.CRM_CUST_INFO (
    CST_ID               INTEGER,
    CST_KEY              STRING,
    CST_FIRSTNAME        STRING,
    CST_LASTNAME         STRING,
    CST_MARITAL_STATUS   STRING,
    CST_GNDR             STRING,
    CST_CREATE_DATE      DATE
);


-- =====================================
-- BRONZE.CRM_PRD_INFO
-- =====================================

CREATE OR REPLACE TABLE BRONZE.CRM_PRD_INFO (
    PRD_ID          INTEGER,
    PRD_KEY         STRING,
    PRD_NM          STRING,
    PRD_COST        INTEGER,
    PRD_LINE        STRING,
    PRD_START_DT    TIMESTAMP,
    PRD_END_DT      TIMESTAMP
);


-- =====================================
-- BRONZE.CRM_SALES_DETAILS
-- =====================================

CREATE OR REPLACE TABLE BRONZE.CRM_SALES_DETAILS (
    SLS_ORD_NUM     STRING,
    SLS_PRD_KEY     STRING,
    SLS_CUST_ID     INTEGER,
    SLS_ORDER_DT    INTEGER,
    SLS_SHIP_DT     INTEGER,
    SLS_DUE_DT      INTEGER,
    SLS_SALES       INTEGER,
    SLS_QUANTITY    INTEGER,
    SLS_PRICE       INTEGER
);


-- =====================================
-- BRONZE.ERP_LOC_A101
-- =====================================

CREATE OR REPLACE TABLE BRONZE.ERP_LOC_A101 (
    CID             STRING,
    CNTRY           STRING
);


-- =====================================
-- BRONZE.ERP_CUST_AZ12
-- =====================================

CREATE OR REPLACE TABLE BRONZE.ERP_CUST_AZ12 (
    CID             STRING,
    BDATE           DATE,
    GEN             STRING
);


-- =====================================
-- BRONZE.ERP_PX_CAT_G1V2
-- =====================================

CREATE OR REPLACE TABLE BRONZE.ERP_PX_CAT_G1V2 (
    ID              STRING,
    CAT             STRING,
    SUBCAT          STRING,
    MAINTENANCE     STRING
);


-- =========================================================
-- STEP 5: CREATE INTERNAL STAGE
-- =========================================================

CREATE OR REPLACE STAGE BRONZE.BRONZE_STAGE;


-- =========================================================
-- STEP 6: FILE FORMAT FOR CSV
-- =========================================================

CREATE OR REPLACE FILE FORMAT BRONZE.CSV_FILE_FORMAT
TYPE = CSV
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
EMPTY_FIELD_AS_NULL = TRUE;


-- =========================================================
-- STEP 7: UPLOAD FILES TO STAGE
-- =========================================================
-- Run these commands from SnowSQL / Snowflake CLI
-- Replace path with your real CSV location
-- =========================================================

-- Example:
-- USE DATABASE SALES_DATA_WAREHOUSE;
-- USE SCHEMA BRONZE;
-- PUT file://D:/Projects/Medallion-Architecture-Project/datasets/source_crm/cust_info.csv
-- @BRONZE.BRONZE_STAGE
-- AUTO_COMPRESS=TRUE;

-- PUT file://D:/Projects/Medallion-Architecture-Project/datasets/source_crm/prd_info.csv
-- @BRONZE.BRONZE_STAGE
-- AUTO_COMPRESS=TRUE;

-- PUT file://D:/Projects/Medallion-Architecture-Project/datasets/source_crm/sales_details.csv
-- @BRONZE.BRONZE_STAGE
-- AUTO_COMPRESS=TRUE;
-- PUT file://D:/Projects/Medallion-Architecture-Project/datasets/source_erp/loc_a101.csv
-- @BRONZE.BRONZE_STAGE
-- AUTO_COMPRESS=TRUE;

-- PUT file://D:/Projects/Medallion-Architecture-Project/datasets/source_erp/cust_az12.csv
-- @BRONZE.BRONZE_STAGE
-- AUTO_COMPRESS=TRUE;

-- PUT file://D:/Projects/Medallion-Architecture-Project/datasets/source_erp/px_cat_g1v2.csv
-- @BRONZE.BRONZE_STAGE
-- AUTO_COMPRESS=TRUE;
-- LIST @BRONZE.BRONZE_STAGE;



-- =========================================================
-- STEP 8: LOAD DATA USING COPY INTO
-- =========================================================

-- =====================================
-- LOAD CRM_CUST_INFO
-- =====================================

COPY INTO BRONZE.CRM_CUST_INFO
FROM @BRONZE.BRONZE_STAGE/cust_info.csv
FILE_FORMAT = (FORMAT_NAME = BRONZE.CSV_FILE_FORMAT)
ON_ERROR = CONTINUE;


-- =====================================
-- LOAD CRM_PRD_INFO
-- =====================================

COPY INTO BRONZE.CRM_PRD_INFO
FROM @BRONZE.BRONZE_STAGE/prd_info.csv
FILE_FORMAT = (FORMAT_NAME = BRONZE.CSV_FILE_FORMAT)
ON_ERROR = CONTINUE;


-- =====================================
-- LOAD CRM_SALES_DETAILS
-- =====================================

COPY INTO BRONZE.CRM_SALES_DETAILS
FROM @BRONZE.BRONZE_STAGE/sales_details.csv
FILE_FORMAT = (FORMAT_NAME = BRONZE.CSV_FILE_FORMAT)
ON_ERROR = CONTINUE;


-- =====================================
-- LOAD ERP_LOC_A101
-- =====================================

COPY INTO BRONZE.ERP_LOC_A101
FROM @BRONZE.BRONZE_STAGE/loc_a101.csv
FILE_FORMAT = (FORMAT_NAME = BRONZE.CSV_FILE_FORMAT)
ON_ERROR = CONTINUE;


-- =====================================
-- LOAD ERP_CUST_AZ12
-- =====================================

COPY INTO BRONZE.ERP_CUST_AZ12
FROM @BRONZE.BRONZE_STAGE/cust_az12.csv
FILE_FORMAT = (FORMAT_NAME = BRONZE.CSV_FILE_FORMAT)
ON_ERROR = CONTINUE;


-- =====================================
-- LOAD ERP_PX_CAT_G1V2
-- =====================================

COPY INTO BRONZE.ERP_PX_CAT_G1V2
FROM @BRONZE.BRONZE_STAGE/px_cat_g1v2.csv
FILE_FORMAT = (FORMAT_NAME = BRONZE.CSV_FILE_FORMAT)
ON_ERROR = CONTINUE;


-- =========================================================
-- STEP 9: VALIDATION CHECKS
-- =========================================================

SELECT COUNT(*) FROM BRONZE.CRM_CUST_INFO;
SELECT COUNT(*) FROM BRONZE.CRM_PRD_INFO;
SELECT COUNT(*) FROM BRONZE.CRM_SALES_DETAILS;
SELECT COUNT(*) FROM BRONZE.ERP_LOC_A101;
SELECT COUNT(*) FROM BRONZE.ERP_CUST_AZ12;
SELECT COUNT(*) FROM BRONZE.ERP_PX_CAT_G1V2;

