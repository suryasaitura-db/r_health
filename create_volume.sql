-- Create R_Health Unity Catalog and Volume
-- This will store public datasets for healthcare analytics

-- Create the catalog
CREATE CATALOG IF NOT EXISTS r_health
COMMENT 'Healthcare Analytics Data Platform';

-- Create a schema to hold volumes and tables
CREATE SCHEMA IF NOT EXISTS r_health.datasets
COMMENT 'Public healthcare datasets and data sources';

-- Create a managed volume for storing raw data files
CREATE VOLUME IF NOT EXISTS r_health.datasets.r_health_volume
COMMENT 'Volume for storing public healthcare datasets (CSV, JSON, Parquet, etc.)';

-- Verify the volume was created
DESCRIBE VOLUME r_health.datasets.r_health_volume;
