#!/bin/bash

# Source environment variables
source .env

# Function to execute SQL command
execute_sql() {
    docker compose exec -T formr_db sh -c "exec mariadb -uroot -p'${MARIADB_ROOT_PASSWORD}'" <<< "$1"
}

# Create migrations database and table if they don't exist
INIT_SQL="
CREATE DATABASE IF NOT EXISTS formr_migrations;
USE formr_migrations;
CREATE TABLE IF NOT EXISTS applied_patches (
    patch_name VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

echo "Initializing migrations database..."
execute_sql "$INIT_SQL"

# Get list of all SQL patches and sort them numerically
PATCHES_DIR="./formr_app/formr/sql/patches"
PATCHES=($(ls -1 "$PATCHES_DIR"/*.sql | sort -V))

# Check if we need to seed initial patches (check if table is empty)
CHECK_PATCHES_SQL="USE formr_migrations; SELECT COUNT(*) FROM applied_patches;"
patch_count=$(execute_sql "$CHECK_PATCHES_SQL" | tail -n 1)

if [ "$patch_count" -eq "0" ]; then
    echo "Seeding migration history with patches up to 039..."
    for patch_file in "${PATCHES[@]}"; do
        patch_name=$(basename "$patch_file")
        # Only seed patches up to 039
        if [[ "$patch_name" =~ ^0[0-3][0-9]_ ]]; then
            SEED_SQL="USE formr_migrations; INSERT INTO applied_patches (patch_name, applied_at) VALUES ('$patch_name', '2024-01-01 00:00:00');"
            execute_sql "$SEED_SQL"
            echo "✓ Seeded patch history: $patch_name"
        fi
    done
fi

# Apply each patch if not already applied
for patch_file in "${PATCHES[@]}"; do
    patch_name=$(basename "$patch_file")
    
    # Check if patch was already applied
    CHECK_SQL="USE formr_migrations; SELECT COUNT(*) FROM applied_patches WHERE patch_name = '$patch_name';"
    is_applied=$(execute_sql "$CHECK_SQL" | tail -n 1)
    
    if [ "$is_applied" -eq "0" ]; then
        echo "Applying patch: $patch_name"
        
        # Apply the patch to formr_db
        if docker compose exec -T formr_db sh -c "exec mariadb -uroot -p'${MARIADB_ROOT_PASSWORD}' formr_db" < "$patch_file"; then
            # Record successful application
            RECORD_SQL="USE formr_migrations; INSERT INTO applied_patches (patch_name) VALUES ('$patch_name');"
            execute_sql "$RECORD_SQL"
            echo "✓ Successfully applied and recorded: $patch_name"
        else
            echo "✗ Failed to apply patch: $patch_name"
            exit 1
        fi
    else
        echo "⚡ Skipping already applied patch: $patch_name"
    fi
done

echo "All patches processed successfully!" 