#!/usr/bin/env bash
#
# Helper function for performing a full environment takedown.
#

# Note: This script expects helper functions like debug, print_section, prompt_yn,
# and color variables (GREEN, YELLOW, RED, NORMAL) to be defined in the
# calling script (cli_setup_wrapper.sh) or sourced from utils.sh before
# sourcing this file.

# Function to perform full takedown of existing environment
perform_full_takedown() {
    print_section "Full Takedown"
    echo -e "${YELLOW}WARNING: This will stop and remove all related Docker containers, volumes, and potentially networks!${NORMAL}"
    echo -e "${YELLOW}It will also remove generated configuration files and data directories.${NORMAL}"
    echo -e "${YELLOW}ALL DOCKER-MANAGED DATA WILL BE LOST! Backup anything important.${NORMAL}"

    if ! prompt_yn "Are you absolutely sure you want to perform a full takedown?" "n"; then
        echo "Takedown canceled."
        return 0
    fi

    echo "Proceeding with full takedown..."

    echo "Stopping and removing Docker containers, volumes, and networks..."
    if docker compose ps -q >/dev/null 2>&1; then
        if ! docker compose down -v --remove-orphans; then
            echo -e "${RED}Error during 'docker compose down'. Some resources might remain.${NORMAL}"
            if ! prompt_yn "Docker down failed. Continue removing files anyway?" "n"; then
                return 1
            fi
        else
            echo -e "${GREEN}Docker containers, volumes, and networks removed.${NORMAL}"
        fi
    else
        echo -e "${GREEN}No running Docker compose services found.${NORMAL}"
    fi

    echo "Removing generated configuration files..."
    local env_backup_file=".env.takedown_bak_$(date +%s)"
    if [ -f ".env" ]; then
        cp ".env" "$env_backup_file" || echo -e "${YELLOW}Warning: Failed to backup .env to $env_backup_file${NORMAL}"
        echo "Skipping removal of .env (backed up to $env_backup_file if possible)."
    fi

    local files_to_remove=(
        "docker-compose.override.yml"
        "formr_app/formr/config/settings.php"
        "mysql/dbinitial/init.sql"
        "formr_app/apache/sites-enabled/formr-ssl.conf"
        "certs/formr.cert.pem"
        "certs/formr.key.pem"
        "formr_access_instructions.md"
    )
    
    local dirs_to_remove=(
        "mysql/data"
        "formr_app/apache/ssl"
        "certs"
    )

    for item in "${files_to_remove[@]}"; do
        if [ -f "$item" ]; then
            rm -f "$item" || echo -e "${YELLOW}Warning: Failed to remove file $item${NORMAL}"
        fi
    done

    for item in "${dirs_to_remove[@]}"; do
        if [ -d "$item" ]; then
            rm -rf "$item" || echo -e "${YELLOW}Warning: Failed to remove directory $item${NORMAL}"
        fi
    done

    echo -e "${GREEN}Takedown complete! Environment is ready for a fresh installation.${NORMAL}"
    return 0
}