# Changelog

All notable changes to the formr Docker development environment compared to the original repository will be documented in this file.

## [1.0.0] - 2025-05-01

### Fixed
- Database initialization issue: Fixed mismatch between database name in schema.sql (`formr`) and the application settings (`formr_db`)
  - Modified `mysql/dbinitial/schema.sql` to use `formr_db` instead of `formr`
  - This ensures the database tables are created in the correct database that the application is configured to use

### Added
- Added troubleshooting section to README.md with instructions for fixing common issues
- Created this CHANGELOG.md file to track modifications from the original repository

## Original Repository

This Docker environment is based on the original formr.org repository: [https://github.com/rubenarslan/formr.org](https://github.com/rubenarslan/formr.org)

