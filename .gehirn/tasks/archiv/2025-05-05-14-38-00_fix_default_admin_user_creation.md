# Fix Default Admin User Creation

## Problem
MySQL client not found in the container during default admin user creation attempt. The error occurs because the script is looking for `mysql` command, but the container is using MariaDB 11.7.2 which uses `mariadb` command instead.

## Debugging Steps
- [x] Examined error messages from failed admin user creation
- [x] Reviewed `user_helpers.sh` script to understand the issue
- [x] Checked docker-compose.yml to confirm MariaDB version (11.7.2)
- [x] Noted that MariaDB 11.x uses `mariadb` command instead of `mysql`

## Solution Plan
- [x] Update `user_helpers.sh` to try both `mariadb` and `mysql` commands
- [x] Add more fallback methods for executing database commands
- [x] Improve error handling and logging
- [x] Test the updated script

## Technical Details
- MariaDB 11.7.2 uses `mariadb` command instead of `mysql`
- The container's healthcheck uses `mariadb-admin` command
- Current script tries `/usr/bin/mysql`, `/opt/mysql/bin/mysql`, and `bash -c "mysql ..."`
- Need to add `/usr/bin/mariadb`, `/opt/mariadb/bin/mariadb`, and `bash -c "mariadb ..."`

## Expected Outcome
- Default admin user creation should succeed
- Script should be more robust by trying multiple command paths