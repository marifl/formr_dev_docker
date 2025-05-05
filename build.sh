#!/usr/bin/env bash
#
# build.sh — build and launch formr Docker development environment.
#
# Usage: ./build.sh
#
# Runs docker compose build and docker compose up -d.

set -e

# Define color functions for better user feedback
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NORMAL="\033[0m"

print_green() { echo -e "${GREEN}$*${NORMAL}"; }
print_red() { echo -e "${RED}$*${NORMAL}"; }
print_yellow() { echo -e "${YELLOW}$*${NORMAL}"; }
print_blue() { echo -e "${BLUE}$*${NORMAL}"; }

# Function to check if sync_config.sh is available
check_sync_config() {
  if [ ! -f "./sync_config.sh" ]; then
    print_yellow "Warning: sync_config.sh not found. Skipping configuration check."
    return 1
  fi
  return 0
}

# Function to check for configuration mismatches
check_config_mismatch() {
  local mismatch=false
  local env_db_pass=""
  local docker_override_db_pass=""
  local settings_db_pass=""
  
  # Check if files exist
  if [ ! -f ".env" ] || [ ! -f "docker-compose.override.yml" ] || [ ! -f "formr_app/formr/config/settings.php" ]; then
    print_yellow "Warning: One or more configuration files missing. Run sync_config.sh to generate them."
    return 0  # Return true (mismatch found)
  fi
  
  # Extract database password from .env
  env_db_pass=$(grep -E "^MARIADB_PASSWORD=" ".env" | sed -E "s/^MARIADB_PASSWORD=//" | tr -d '"')
  
  # Extract database password from docker-compose.override.yml
  docker_override_db_pass=$(grep "MARIADB_PASSWORD:" "docker-compose.override.yml" | awk '{print $2}')
  
  # Extract database password from settings.php
  settings_db_pass=$(grep -A2 "'password'" "formr_app/formr/config/settings.php" | head -1 | awk -F "=> " '{print $2}' | sed "s/'//g" | sed 's/,.*//')
  
  # Check for placeholder passwords
  if [ "$env_db_pass" = "generate-password" ]; then
    print_yellow "Warning: Placeholder password found in .env"
    return 0  # Return true (mismatch found)
  fi
  
  # Check for password mismatches
  if [ -n "$env_db_pass" ] && [ -n "$docker_override_db_pass" ] && [ "$env_db_pass" != "$docker_override_db_pass" ]; then
    print_yellow "Warning: Database password in .env doesn't match docker-compose.override.yml"
    return 0  # Return true (mismatch found)
  fi
  
  if [ -n "$env_db_pass" ] && [ -n "$settings_db_pass" ] && [ "$env_db_pass" != "$settings_db_pass" ]; then
    print_yellow "Warning: Database password in .env doesn't match settings.php"
    return 0  # Return true (mismatch found)
  fi
  
  return 1  # Return false (no mismatch found)
}

# Function to prompt user with yes/no question
confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local response
  
  if [ "$default" = "y" ]; then
    prompt="$prompt [Y/n]: "
  else
    prompt="$prompt [y/N]: "
  fi
  
  read -p "$prompt" response
  response="${response:-$default}"
  
  if echo "$response" | grep -iq "^y"; then
    return 0
  else
    return 1
  fi
}

# Check and offer to sync configurations
if check_sync_config; then
  if check_config_mismatch; then
    print_red "Configuration mismatches detected!"
    print_yellow "Your configuration files (.env, docker-compose.override.yml, settings.php) are not in sync."
    print_yellow "This may cause issues when running the application."
    
    if confirm "Would you like to run sync_config.sh to fix these issues before building?" "y"; then
      print_blue "Running sync_config.sh with --force option..."
      ./sync_config.sh --force
      print_green "Configuration synchronized successfully."
    else
      print_yellow "Continuing with mismatched configurations. This might cause runtime issues."
    fi
  else
    print_green "Configuration files are in sync. Proceeding with build."
  fi
fi

print_blue "Building Docker images…"
docker compose build

print_blue "Starting Docker containers in detached mode…"
docker compose up -d

print_green "Docker environment is up!"
echo "To check status: docker compose ps"
echo "To stop:         docker compose down"

echo ""
echo "====================== LOGIN INFORMATION ======================"
echo "FormR Application URL: http://localhost"
echo "OpenCPU URL:           http://localhost:8080"
echo ""
echo "Admin Login Credentials:"
echo "Email:    rform@researchmixtapes.com"
echo "Password: VvscXmQKghIln2Xj"
echo "=============================================================="
echo ""

print_blue "Waiting for FormR application to initialize..."
echo "This may take a few seconds..."
sleep 10

print_blue "Creating admin user from environment variables..."
# Extract credentials from .env
ADMIN_EMAIL=$(grep -E "^FORMR_EMAIL=" ".env" | sed -E "s/^FORMR_EMAIL=//" | tr -d '"')
ADMIN_PASSWORD=$(grep -E "^FORMR_PASSWORD=" ".env" | sed -E "s/^FORMR_PASSWORD=//" | tr -d '"')

# Create the admin user with level 2 (superadmin)
docker exec -it formr_app bash -c "cd /formr && php bin/add_user.php -e $ADMIN_EMAIL -p $ADMIN_PASSWORD -l 2"

print_green "Admin user created successfully!"
echo "You can now log in with the credentials shown above."
echo ""
