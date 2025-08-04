-- 01_create_task.sql

-- 1) Ensure we’re operating in the right context
USE DATABASE DUMMYJSON_PIPELINE;
USE SCHEMA RAW_STAGE;

-- 2) Create or update the incremental‐load task
CREATE OR REPLACE TASK RAW_STAGE_LOAD_TASK
  WAREHOUSE = RAW_LOAD_WH
  SCHEDULE  = 'USING CRON 0 11 * * 1 UTC'
AS
  -- Load only new product files
  INSERT INTO PRODUCTS_RAW (json_data, file_name)
    SELECT json_data, file_name
      FROM PRODUCTS_EXT
     WHERE file_name NOT IN (SELECT file_name FROM PRODUCTS_RAW);

  -- Load only new cart files
  INSERT INTO CARTS_RAW (json_data, file_name)
    SELECT json_data, file_name
      FROM CARTS_EXT
     WHERE file_name NOT IN (SELECT file_name FROM CARTS_RAW);

  -- Load only new user files
  INSERT INTO USERS_RAW (json_data, file_name)
    SELECT json_data, file_name
      FROM USERS_EXT
     WHERE file_name NOT IN (SELECT file_name FROM USERS_RAW);
  
;

-- 3) Activate (or re-activate) the task
ALTER TASK RAW_STAGE_LOAD_TASK RESUME;

-- 4) (Optional) Verify that the task exists
SHOW TASKS LIKE 'RAW_STAGE_LOAD_TASK';
