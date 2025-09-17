/* Initialize PostgreSQL for Formbricks

   Below commands are intended to be run once as admin/superuser role before a new Formbricks instance is started for the first time.
*/

-- Create dedicated DB
CREATE DATABASE formbricks;

-- Configure user for Formbricks
CREATE ROLE "formbricks" WITH LOGIN PASSWORD 'REPLACE-ME';
GRANT ALL PRIVILEGES ON DATABASE "formbricks" TO "formbricks";

-- NOTE: everything below must be run while connected to the "formbricks" DB!!!

-- Install extensions required by Formbricks
CREATE EXTENSION IF NOT EXISTS vector;

-- Grant privileges to Formbricks user
GRANT ALL PRIVILEGES ON SCHEMA "public" TO "formbricks";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA "public" TO "formbricks";
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA "public" TO "formbricks";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA "public" TO "formbricks";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT ALL PRIVILEGES ON SEQUENCES TO "formbricks";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT ALL PRIVILEGES ON ROUTINES TO "formbricks";
ALTER DEFAULT PRIVILEGES IN SCHEMA "public" GRANT ALL PRIVILEGES ON TABLES TO "formbricks";
