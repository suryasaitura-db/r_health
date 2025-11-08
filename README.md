# R_Health

Healthcare Analytics and Data Platform

This repository contains Databricks resources for healthcare data analytics:
- Databricks Apps
- Databricks Jobs
- SQL Serverless Queries
- Unity Catalog Volume for public datasets

## Unity Catalog Resources

### Created Resources
- **Schema**: `hls_amer_catalog.r_health`
- **Volume**: `hls_amer_catalog.r_health.r_health_volume`
- **Volume Path**: `/Volumes/hls_amer_catalog/r_health/r_health_volume`

### Setup Scripts
- `create_catalog_volume.py` - Creates Unity Catalog schema and volume
- `create_volume.sql` - SQL statements for catalog/volume creation

## Usage

To create the Unity Catalog volume:
```bash
python3 create_catalog_volume.py
```

The volume is ready to store public healthcare datasets in various formats (CSV, JSON, Parquet, etc.).
