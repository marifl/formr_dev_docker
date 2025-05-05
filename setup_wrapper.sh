#!/usr/bin/env bash
#
# cli.sh — Interactive entrypoint for setting up and running the formr development environment.
#
# Usage: ./cli.sh
#

# Comment out 'set -e' to prevent immediate exit on any error
# set -e

# Color definitions are now handled in scripts/utils.sh

# Source helper scripts in correct dependency order
SCRIPT_DIR=$(dirname "$0")
# utils.sh must be first as other scripts depend on its functions
source "$SCRIPT_DIR/scripts/utils.sh"
source "$SCRIPT_DIR/scripts/config_helpers.sh"
source "$SCRIPT_DIR/scripts/docker_helpers.sh"
source "$SCRIPT_DIR/scripts/https_helpers.sh"
source "$SCRIPT_DIR/scripts/coredns_helpers.sh"
source "$SCRIPT_DIR/scripts/takedown_helpers.sh"
source "$SCRIPT_DIR/scripts/user_helpers.sh"

# Initialize variables
NETWORK_SETUP_DONE=false
SERVER_IP=""

# Utility functions are in scripts/utils.sh
# Helper functions are in their respective helper scripts

# Function to update existing installation
update_existing_installation() {
    print_section "Update Existing Installation"
    
    # Check if Docker containers exist
    if ! docker compose ps -q &>/dev/null; then
        echo -e "${YELLOW}No existing Docker containers found. Consider using fresh installation instead.${NORMAL}"
        if ! prompt_yn "Continue with update anyway?"; then
            return 1
        fi
    fi
    
    # Check if config files exist
    if [[ ! -f ".env" || ! -f "formr_app/formr/config/settings.php" ]]; then
        echo -e "${YELLOW}Configuration files missing. Update might not work correctly.${NORMAL}"
        if ! prompt_yn "Continue with update anyway?"; then
            return 1
        fi
    fi
    
    # Anstatt docker-compose.override.yml zu generieren, prüfe die docker-compose.yml
    echo "Verifying Docker Compose configuration..."

    # Use helper function to check/update docker-compose.yml and handle override file
    if ! sync_docker_config; then
         echo -e "${RED}Failed to synchronize Docker configuration. Update aborted.${NORMAL}"
         return 1
    fi
    
    # Setup CoreDNS for dynamic IP routing
    if prompt_yn "Would you like to setup/update CoreDNS configuration for dynamic IP routing?"; then
        setup_coredns_config
    fi
    
    # Rebuild and restart containers
    if prompt_yn "Would you like to rebuild and restart the Docker containers?"; then
        echo "Rebuilding and restarting Docker containers..."
        docker compose down && docker compose up -d --build
        echo -e "${GREEN}Docker containers have been rebuilt and restarted.${NORMAL}"
    else
        echo "Skipping container rebuild."
    fi
    
    # Setup local network access
    if [ -f "./setup_local_network.sh" ] && prompt_yn "Update local network access configuration?"; then
        chmod +x ./setup_local_network.sh
        ./setup_local_network.sh
        
        # Set variables for displaying network access options later
        if [ -f "./formr_access_instructions.md" ]; then
            NETWORK_SETUP_DONE=true
            SERVER_IP=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' ./formr_access_instructions.md | head -1)
        fi
    fi
    
    echo -e "${GREEN}Update completed successfully!${NORMAL}"
    return 0
}

# Functions check_containers_running, retry_build, validate_docker_compose moved to scripts/docker_helpers.sh

# Initial selection of installation mode
print_section "FormR Development Environment Setup"
echo -e "Welcome to the FormR development environment setup!"
echo -e "This script will guide you through setting up or managing your FormR environment.\n"

select_from_options "What would you like to do?" "Fresh Installation" "Update Existing Installation" "Full Takedown and Reinstall"
SETUP_MODE=$?

# Handle the selected mode
case $SETUP_MODE in
    0) # Fresh Installation
        echo -e "\nProceeding with fresh installation...\n"
        ;;
    1) # Update Existing Installation
        echo -e "\nProceeding with update of existing installation...\n"
        if update_existing_installation; then
            # Set a flag to skip the installation steps
            SKIP_INSTALLATION=true
        else
            echo -e "${YELLOW}Update failed or was canceled. Would you like to try a fresh installation?${NORMAL}"
            if prompt_yn "Proceed with fresh installation?"; then
                echo -e "\nProceeding with fresh installation...\n"
            else
                echo "Exiting."
                exit 0
            fi
        fi
        ;;
    2) # Full Takedown and Reinstall
        echo -e "\nPerforming full takedown before fresh installation...\n"
        # Call perform_full_takedown from helper script
        if ! perform_full_takedown; then
             echo -e "${RED}Takedown failed. Please check errors above.${NORMAL}"
             exit 1
        fi
        echo -e "\nProceeding with fresh installation...\n"
        ;;
    *)
        echo -e "${RED}Invalid option selected. Exiting.${NORMAL}"
        exit 1
        ;;
esac

# Only continue with installation steps if not just updating
if [ "$SKIP_INSTALLATION" != "true" ]; then
    # Step 1: Setup config files using helper
    if ! setup_env_files; then
         echo -e "${RED}Initial environment file setup failed. Exiting.${NORMAL}"
         exit 1
    fi

    # Step 2: Synchronize configuration using helpers
    print_section "Step 2: Configuration Synchronization"
    echo -e "Ensuring Docker configuration uses environment variables and generating init.sql."

    if prompt_yn "Verify/optimize Docker config & generate init.sql?" "y"; then
        # Sync docker-compose.yml and handle override file
        if ! sync_docker_config; then
             echo -e "${RED}Docker configuration synchronization failed. Please check manually.${NORMAL}"
             # Decide if this is fatal or allow continuation
             # exit 1
        fi

        # Generate init.sql (requires .env to be sourced or variables passed)
        # Ensure .env is loaded before calling this if variables aren't exported globally
        if [ -f ".env" ]; then
             set -a
             source ".env"
             set +a
             if ! generate_init_sql; then
                  echo -e "${RED}Failed to generate init.sql. Database might not initialize correctly.${NORMAL}"
                  # exit 1
             fi
             # Unset sensitive vars if necessary
             unset MARIADB_DATABASE MARIADB_USER MARIADB_PASSWORD MARIADB_ROOT_PASSWORD
        else
             echo -e "${RED}Error: .env file not found. Cannot generate init.sql.${NORMAL}"
             # exit 1
        fi
        echo -e "${GREEN}Configuration synchronization complete.${NORMAL}"
    else
        echo -e "${YELLOW}Skipping configuration synchronization.${NORMAL}"
    fi

    # Step 3: Set up CoreDNS configuration
    echo
    print_section "Step 3: Dynamic IP Routing Setup"
    echo -e "Setting up CoreDNS for dynamic IP address routing in your local network."
    echo -e "This will allow formr.local to be accessible from any device on your network."

    if prompt_yn "Would you like to set up dynamic IP routing with CoreDNS?"; then
        # Call setup_coredns_config from helper script
        if ! setup_coredns_config; then
             echo -e "${RED}CoreDNS setup failed. Check logs above.${NORMAL}"
             # Decide if fatal or continue
             # exit 1
        fi
    else
        echo -e "${YELLOW}Warning: Skipping CoreDNS setup means formr.local may only be accessible from this machine.${NORMAL}"
        echo -e "You can set it up later by rerunning this script."
    fi

    # Step 4: Build and launch Docker using helper
    print_section "Step 4: Build and Launch Docker Environment"
    if prompt_yn "Proceed to build and start the Docker containers?"; then
        if ! build_and_launch_docker; then
             echo -e "${RED}Failed to build and launch Docker environment. Check logs above.${NORMAL}"
             exit 1
        fi
    else
        echo "Skipping Docker build and launch. You can start the environment later."
        # Maybe offer commands like 'docker compose up -d'
        exit 0
# Ensure /formr/tmp directory exists and has correct permissions inside the formr_app container
    echo "Ensuring /formr/tmp directory exists and has correct permissions in formr_app container..."
    if ! docker exec formr_app mkdir -p /formr/tmp || ! docker exec formr_app chown www-data:www-data /formr/tmp; then
        echo -e "${RED}Failed to create or set permissions for /formr/tmp in formr_app container.${NORMAL}"
        # Decide if this is fatal or allow continuation
        # exit 1
    fi
    echo -e "${GREEN}/formr/tmp directory setup complete.${NORMAL}"
    fi

    # Step 6: Create default admin user
    print_section "Step 6: Create Default Admin User"
    if [ "$SKIP_INSTALLATION" != "true" ]; then
        if ! create_default_admin_user; then
            echo -e "${YELLOW}Warning: Failed to create default admin user. You may need to create it manually.${NORMAL}"
        fi
    fi

    # Step 5: Configure local network access with HTTPS using helper
    # The setup_https_access function handles user prompts, setup, and restart prompt internally.
    if ! setup_https_access; then
        echo -e "${RED}HTTPS setup failed or was skipped with errors. Check logs above.${NORMAL}"
    fi

    # Final message
    echo
    print_section "Setup Complete!"
    echo -e "${GREEN}The formr environment is now running!${NORMAL}"
    echo -e "If you make future changes to your .env file, run ./sync_config.sh to ensure all configuration files stay in sync."
fi

# Display access options using helper function
# Pass relevant variables if they are not exported globally by helpers
display_access_options
