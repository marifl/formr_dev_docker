#!/usr/bin/env bash
#
# Helper functions for user management in cli_setup_wrapper.sh
#

# Note: This script expects helper functions like print_section, prompt_yn,
# and color variables (GREEN, YELLOW, RED, NORMAL) to be defined in the
# calling script (cli_setup_wrapper.sh) or sourced from utils.sh before
# sourcing this file.

# Function to create default admin user from .env credentials
create_default_admin_user() {
    # Returns 0 on success, 1 on failure

    local env_file=".env"
    local mariadb_database=""
    local mariadb_user=""
    local mariadb_password=""
    local mariadb_root_password=""
    local formr_email=""
    local formr_password=""
    local hashed_password=""

    # Check if .env file exists
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Error: .env file not found. Cannot create default admin user.${NORMAL}"
        return 1
    fi

    # Extract values from .env
    mariadb_database=$(grep -E "^MARIADB_DATABASE=" "$env_file" | sed -E "s/^MARIADB_DATABASE=//")
    mariadb_user=$(grep -E "^MARIADB_USER=" "$env_file" | sed -E "s/^MARIADB_USER=//")
    mariadb_password=$(grep -E "^MARIADB_PASSWORD=" "$env_file" | sed -E "s/^MARIADB_PASSWORD=//")
    mariadb_root_password=$(grep -E "^MARIADB_ROOT_PASSWORD=" "$env_file" | sed -E "s/^MARIADB_ROOT_PASSWORD=//")
    formr_email=$(grep -E "^FORMR_EMAIL=" "$env_file" | sed -E "s/^FORMR_EMAIL=//")
    formr_password=$(grep -E "^FORMR_PASSWORD=" "$env_file" | sed -E "s/^FORMR_PASSWORD=//")

    # Validate extracted values
    if [ -z "$mariadb_database" ] || [ -z "$mariadb_user" ] || [ -z "$mariadb_password" ] || 
       [ -z "$mariadb_root_password" ] || [ -z "$formr_email" ] || [ -z "$formr_password" ]; then
        echo -e "${RED}Error: Missing required values in .env file.${NORMAL}"
        return 1
    fi

    # Generate password hash for the password
    hashed_password=$(docker run --rm php:8.2-cli php -r "echo password_hash(\$argv[1], PASSWORD_DEFAULT);" -- "$formr_password")

    if [ $? -ne 0 ] || [ -z "$hashed_password" ]; then
        echo -e "${RED}Error: Failed to generate password hash for default admin user.${NORMAL}"
        return 1
    fi

    # Prepare SQL command using extracted values
    local create_user_sql="
CREATE DATABASE IF NOT EXISTS $mariadb_database;
CREATE USER IF NOT EXISTS '$mariadb_user'@'%' IDENTIFIED BY '$mariadb_password';
GRANT ALL PRIVILEGES ON $mariadb_database.* TO '$mariadb_user'@'%';
INSERT IGNORE INTO $mariadb_database.survey_users 
    (email, password, admin, email_verified, created, modified) 
VALUES 
    ('$formr_email', '$hashed_password', 1, 1, NOW(), NOW());
FLUSH PRIVILEGES;"

    # Execute SQL command
    if ! docker exec -it formr_db mariadb -u root -p"$mariadb_root_password" -e "$create_user_sql"; then
        echo -e "${RED}Error: Failed to create or update default admin user in the database.${NORMAL}"
        return 1
    fi

    echo -e "${GREEN}Default admin user and database configuration completed successfully.${NORMAL}"
    return 0
}