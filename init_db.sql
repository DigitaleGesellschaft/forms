/* Initialize PostgreSQL for Formbricks

   Below commands are intended to be run once before a new Formbricks instance is started for the first time.
*/
 
-- Switch to `admin` role (errors if not authorized)
SET ROLE admin;

-- Create dedicated DB
CREATE DATABASE formbricks WITH OWNER admin;

-- Install extensions required by Formbricks
CREATE EXTENSION IF NOT EXISTS vector;

-- Configure user for Formbricks
CREATE ROLE "formbricks" WITH LOGIN PASSWORD 'REPLACE-ME' ROLE "admin";
GRANT ALL PRIVILEGES ON DATABASE "formbricks" TO "formbricks";
GRANT ALL PRIVILEGES ON SCHEMA "public" TO "formbricks";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA "public" TO "formbricks";
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA "public" TO "formbricks";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA "public" TO "formbricks";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT ALL PRIVILEGES ON SEQUENCES TO "formbricks";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT ALL PRIVILEGES ON ROUTINES TO "formbricks";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT ALL PRIVILEGES ON TABLES TO "formbricks";
