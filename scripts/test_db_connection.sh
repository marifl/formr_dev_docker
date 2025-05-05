#!/usr/bin/env bash
# Test database connection
# This script tests the database connection to verify that our setup is working correctly

# Find script directory regardless of where it's called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Source shared utilities
source "${SCRIPT_DIR}/_lib.sh"

# Load environment variables
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
else
    log "ERROR: .env file not found"
    exit 1
fi

log "Testing database connection..."

# Check if database container is running
if ! docker ps | grep -q formr_db; then
    log "ERROR: Database container (formr_db) is not running"
    log "Run ./build.sh first to start all containers"
    exit 1
fi

# Test connection with root credentials
log "Testing connection with root credentials..."
if docker exec formr_db mysql -hlocalhost -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT 'Root connection successful';" 2>/dev/null; then
    log "✓ Root connection successful"
else
    log "✗ Root connection failed. Check the root password in .env file"
fi

# Test connection with user credentials
log "Testing connection with user credentials..."
if docker exec formr_db mysql -hlocalhost -u"${MARIADB_USER}" -p"${MARIADB_PASSWORD}" -e "SELECT 'User connection successful';" 2>/dev/null; then
    log "✓ User connection successful"
else
    log "✗ User connection failed. Check the user credentials in .env file"
fi

# Test connection to specific database
log "Testing connection to ${MARIADB_DATABASE} database..."
if docker exec formr_db mysql -hlocalhost -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "USE ${MARIADB_DATABASE}; SELECT 'Database connection successful';" 2>/dev/null; then
    log "✓ Database connection successful"
else
    log "✗ Database connection failed. The database might not exist"
fi

# Test connection to formr_migrations database
log "Testing connection to formr_migrations database..."
if docker exec formr_db mysql -hlocalhost -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "USE formr_migrations; SELECT 'Migrations database connection successful';" 2>/dev/null; then
    log "✓ Migrations database connection successful"
else
    log "✗ Migrations database connection failed. The migrations database might not exist"
fi

log "Database connection tests completed"
