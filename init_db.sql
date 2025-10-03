/* Initialize PostgreSQL for Formbricks

   Below commands are intended to be run once as admin/superuser role before a new Formbricks instance is deployed for the first time.
*/

-- Create user for Formbricks
CREATE ROLE "formbricks" WITH LOGIN PASSWORD 'REPLACE-ME';

-- Create dedicated DB
CREATE DATABASE formbricks WITH OWNER "formbricks";

-- NOTE: everything below must be run while connected to the "formbricks" DB (`\c formbricks`)!

-- Install extensions required by Formbricks
CREATE EXTENSION IF NOT EXISTS vector;
