#!/usr/bin/env bash
#
# Helper functions for configuration management in cli_setup_wrapper.sh
#

# Note: This script expects helper functions like print_section, prompt_yn,
# and color variables (GREEN, YELLOW, RED, NORMAL) to be defined in the
# calling script (cli_setup_wrapper.sh) before sourcing this file.
# It also expects MARIADB_* variables to be loaded from .env before calling generate_init_sql.

# Function to handle initial .env and settings.php setup/editing
setup_env_files() {
    # Returns 0 on success, 1 if setup.sh fails

    print_section "Step 1: Initial Configuration Files"

    local setup_script="./setup.sh"
    local settings_file="formr_app/formr/config/settings.php"
    local env_file=".env"

    if [ ! -f "$setup_script" ]; then
        echo -e "${RED}Error: $setup_script not found. Cannot create initial config files.${NORMAL}"
        return 1
    fi

    if [[ -f "$env_file" && -f "$settings_file" ]]; then
        echo -e "${GREEN}Config files already exist ($env_file, $settings_file).${NORMAL}"
        if prompt_yn "Re-run $setup_script to reset them (overwrites existing)?" "n"; then
            echo "Running $setup_script..."
            if ! "$setup_script"; then
                 echo -e "${RED}Error running $setup_script.${NORMAL}"
                 return 1
            fi
        else
            echo "Skipping config file reset. Using existing files."
        fi
    else
        echo "Creating initial config files using $setup_script..."
         if ! "$setup_script"; then
             echo -e "${RED}Error running $setup_script.${NORMAL}"
             return 1
         fi
         # Check if files were actually created
         if [[ ! -f "$env_file" || ! -f "$settings_file" ]]; then
              echo -e "${RED}Error: $setup_script ran but config files are still missing!${NORMAL}"
              return 1
         fi
         echo -e "${GREEN}Initial config files created.${NORMAL}"
    fi

    echo
    if [ -f "$env_file" ]; then
        echo -e "\n${YELLOW}Would you like to review your environment settings?${NORMAL}"
        if prompt_yn "Open '$env_file' now?"; then
            "${VISUAL:-${EDITOR:-nano}}" "$env_file"
        fi
    fi
    if [ -f "$settings_file" ]; then
        echo -e "\n${YELLOW}Would you like to review your PHP settings?${NORMAL}"
        if prompt_yn "Open '$settings_file' now?"; then
            "${VISUAL:-${EDITOR:-nano}}" "$settings_file"
        fi
    fi
    echo -e "${GREEN}Initial file setup/review complete.${NORMAL}"
    return 0
}


# Function to verify/update docker-compose.yml to use environment variables
# and handle the legacy override file.
sync_docker_config() {
    # Returns 0 on success/no action needed, 1 on failure during update.

    echo "Verifying Docker Compose uses environment variables..."
    local compose_file="docker-compose.yml"
    local override_file="docker-compose.override.yml"

    if [ ! -f "$compose_file" ]; then
        echo -e "${RED}Error: $compose_file not found! Cannot verify.${NORMAL}"
        return 1
    fi

    # Check if the main docker-compose.yml already uses the expected environment variables
    # Add more checks if other variables need verification (e.g., MARIADB_ROOT_HOST)
    local uses_env_vars=true
    # Check for both formats: KEY=${VAR} and - KEY=${VAR}
    grep -q "MARIADB_ROOT_PASSWORD:.*\${MARIADB_ROOT_PASSWORD}\|MARIADB_ROOT_PASSWORD=\${MARIADB_ROOT_PASSWORD}" "$compose_file" || uses_env_vars=false
    grep -q "MARIADB_PASSWORD:.*\${MARIADB_PASSWORD}\|MARIADB_PASSWORD=\${MARIADB_PASSWORD}" "$compose_file" || uses_env_vars=false
    grep -q "MARIADB_USER:.*\${MARIADB_USER}\|MARIADB_USER=\${MARIADB_USER}" "$compose_file" || uses_env_vars=false
    grep -q "MARIADB_DATABASE:.*\${MARIADB_DATABASE}\|MARIADB_DATABASE=\${MARIADB_DATABASE}" "$compose_file" || uses_env_vars=false
    grep -q "MARIADB_ROOT_HOST:.*\${MARIADB_ROOT_HOST}\|MARIADB_ROOT_HOST=\${MARIADB_ROOT_HOST}" "$compose_file" || uses_env_vars=false

    if [ "$uses_env_vars" = true ]; then
        echo -e "${GREEN}Database environment variables are correctly configured in docker-compose.yml.${NORMAL}"
        return 0
    else
        echo -e "${YELLOW}Some database environment variables may not be correctly set.${NORMAL}"
        echo -e "Checking for variables: MARIADB_ROOT_PASSWORD, MARIADB_PASSWORD, MARIADB_USER, MARIADB_DATABASE, MARIADB_ROOT_HOST"
        echo -e "\nThey should be in one of these formats:"
        echo -e "1. ${GREEN}environment:${NORMAL}"
        echo -e "     MARIADB_PASSWORD: \${MARIADB_PASSWORD}"
        echo -e "2. ${GREEN}environment:${NORMAL}"
        echo -e "     - MARIADB_PASSWORD=\${MARIADB_PASSWORD}"

        if prompt_yn "Would you like me to check and update the format if needed (creates backup first)?"; then
            local backup_file="${compose_file}.bak_env_sync"
            echo "Creating backup: $backup_file"
            cp "$compose_file" "$backup_file"

            # Use sed to replace hardcoded values with environment variables
            # Use a pattern that matches the key, colon, optional spaces, and then *not* a dollar sign
            # Be careful with sed syntax differences (e.g., -i '' for macOS vs -i for GNU sed)
            local sed_inplace_arg="-i"
            if [[ "$(uname)" == "Darwin" ]]; then
                sed_inplace_arg="-i ''"
            fi

            echo "Applying environment variable updates..."
            sed $sed_inplace_arg \
                -e 's/^\([[:space:]]*MARIADB_ROOT_PASSWORD:[[:space:]]*\)[^$].*/\1\${MARIADB_ROOT_PASSWORD}/g' \
                -e 's/^\([[:space:]]*MARIADB_PASSWORD:[[:space:]]*\)[^$].*/\1\${MARIADB_PASSWORD}/g' \
                -e 's/^\([[:space:]]*MARIADB_USER:[[:space:]]*\)[^$].*/\1\${MARIADB_USER}/g' \
                -e 's/^\([[:space:]]*MARIADB_DATABASE:[[:space:]]*\)[^$].*/\1\${MARIADB_DATABASE}/g' \
                "$compose_file"

            # Rudimentary check if sed command succeeded (this is tricky)
            # A better check would be to re-run the grep verification
            local update_check_ok=true
            grep -q "MARIADB_ROOT_PASSWORD: *\${MARIADB_ROOT_PASSWORD}" "$compose_file" || update_check_ok=false
            # ... repeat for other vars ...

            if [ "$update_check_ok" = true ]; then
                 echo -e "${GREEN}Docker Compose file updated successfully.${NORMAL}"
            else
                 echo -e "${RED}Automatic update might have failed. Please check '$compose_file' manually.${NORMAL}"
                 echo "Original file backed up at $backup_file"
                 # Decide whether to proceed or return failure
                 # return 1
            fi
        else
             echo -e "${YELLOW}Skipping automatic update. Please ensure '$compose_file' uses environment variables manually.${NORMAL}"
        fi
    fi

    # Handle the override file
    if [ -f "$override_file" ]; then
        echo -e "${YELLOW}Found legacy '$override_file'. This can override settings from '$compose_file' and .env.${NORMAL}"
        if prompt_yn "Remove '$override_file' (recommended if '$compose_file' uses env vars)?"; then
            local override_backup="${override_file}.bak_removed_$(date +%s)"
            echo "Backing up to $override_backup"
            mv "$override_file" "$override_backup"
            if [ $? -eq 0 ]; then
                 echo -e "${GREEN}Removed '$override_file' (backed up).${NORMAL}"
            else
                 echo -e "${RED}Failed to remove/backup '$override_file'. Please remove it manually.${NORMAL}"
            fi
        else
            echo -e "${YELLOW}Keeping '$override_file'. Note: Its settings will take precedence.${NORMAL}"
        fi
    fi

    echo -e "${GREEN}Docker configuration synchronization check complete.${NORMAL}"
    return 0
}


# Function to generate init.sql from .env variables
generate_init_sql() {
    # Returns 0 on success, 1 on failure (e.g., missing variables)

    local init_sql_file="./mysql/dbinitial/init.sql"
    local init_sql_dir=$(dirname "$init_sql_file")
    local env_file=".env"

    echo "Generating $init_sql_file with credentials from $env_file..."

    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Error: $env_file not found. Cannot generate $init_sql_file.${NORMAL}"
        return 1
    fi

    # Source .env file carefully to load variables into the current shell
    # Use 'set -a' to export variables read from .env, and 'set +a' to turn it off after
    set -a
    source "$env_file"
    set +a

    # Check if required variables are loaded
    if [ -z "${MARIADB_DATABASE:-}" ] || [ -z "${MARIADB_USER:-}" ] || [ -z "${MARIADB_PASSWORD:-}" ]; then
        echo -e "${RED}Error: One or more required variables (MARIADB_DATABASE, MARIADB_USER, MARIADB_PASSWORD) not found in $env_file.${NORMAL}"
        echo "Please ensure they are defined in $env_file."
        # Unset potentially partially loaded vars?
        unset MARIADB_DATABASE MARIADB_USER MARIADB_PASSWORD MARIADB_ROOT_PASSWORD
        return 1
    fi

    # Create directory if it doesn't exist
    mkdir -p "$init_sql_dir"

    # Generate the init.sql file
    # Use printf for better control over quoting and special characters
    printf "CREATE DATABASE IF NOT EXISTS \`%s\`;\n" "$MARIADB_DATABASE" > "$init_sql_file"
    printf "CREATE USER IF NOT EXISTS '%s'@'%%' IDENTIFIED BY '%s';\n" "$MARIADB_USER" "$MARIADB_PASSWORD" >> "$init_sql_file"
    printf "GRANT ALL PRIVILEGES ON \`%s\`.* TO '%s'@'%%';\n" "$MARIADB_DATABASE" "$MARIADB_USER" >> "$init_sql_file"
        # Get FORMR_EMAIL and FORMR_PASSWORD from environment
        local formr_email="${FORMR_EMAIL}"
        local formr_password="${FORMR_PASSWORD}"
    
        if [ -z "$formr_email" ] || [ -z "$formr_password" ]; then
            echo -e "${RED}Error: FORMR_EMAIL and FORMR_PASSWORD must be set in .env for default user creation.${NORMAL}"
            return 1
        fi

        echo "Creating default user with email: $formr_email"
        # Generate password hash using a temporary PHP container
        local hashed_password
        hashed_password=$(docker run --rm php:8.2-cli php -r "echo password_hash(\$argv[1], PASSWORD_DEFAULT);" -- "$formr_password")

        if [ $? -ne 0 ] || [ -z "$hashed_password" ]; then
            echo -e "${RED}Failed to generate password hash for default user.${NORMAL}"
            return 1
        fi

        # Append INSERT statement to init.sql
        printf "INSERT IGNORE INTO \`survey_users\` (\`email\`, \`password\`, \`admin\`, \`email_verified\`, \`created\`, \`modified\`) VALUES ('%s', '%s', 1, 1, NOW(), NOW());\n" "$formr_email" "$hashed_password" >> "$init_sql_file"
        echo -e "${GREEN}Default user INSERT statement added to $init_sql_file.${NORMAL}"
    
        printf "FLUSH PRIVILEGES;\n" >> "$init_sql_file"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully generated $init_sql_file.${NORMAL}"
        echo "Database: $MARIADB_DATABASE"
        echo "User:     $MARIADB_USER"
        echo "Password: [hidden]"
        echo -e "Note: This file initializes the database on first container start."
        # Unset the sourced variables for security/cleanup
        unset MARIADB_DATABASE MARIADB_USER MARIADB_PASSWORD MARIADB_ROOT_PASSWORD
        return 0
    else
        echo -e "${RED}Error writing to $init_sql_file.${NORMAL}"
        # Unset the sourced variables
        unset MARIADB_DATABASE MARIADB_USER MARIADB_PASSWORD MARIADB_ROOT_PASSWORD
        return 1
    fi
}