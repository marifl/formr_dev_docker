#!/usr/bin/env bash
#
# formr_setup.sh — Simple setup script for FormR development environment
#

# Set colors for better readability
BOLD="\033[1m"
NORMAL="\033[0m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"

print_header() {
  echo -e "\n${BOLD}${BLUE}=== $1 ===${NORMAL}\n"
}

# Check Docker is installed
if ! command -v docker &>/dev/null; then
  echo -e "${RED}Error: Docker is not installed or not in PATH${NORMAL}"
  echo "Please install Docker Desktop or Docker Engine first."
  exit 1
fi

# Main menu
print_header "FormR Setup"
echo "Welcome to the FormR development environment setup."
echo "This script will help you set up and run FormR locally."

PS3="Select an option (1-4): "
options=("Install/Reinstall FormR" "Fix Docker Compose File" "Start/Restart Services" "Exit")
select opt in "${options[@]}"; do
  case $opt in
    "Install/Reinstall FormR")
      print_header "Installing FormR"
      
      # Check and fix docker-compose.yml if needed
      ./fix_compose.sh
      
      # Run setup script
      if [ -f "./setup.sh" ]; then
        echo "Running setup.sh to initialize configuration..."
        ./setup.sh
      else
        echo -e "${RED}Error: setup.sh not found${NORMAL}"
        exit 1
      fi
      
      # Generate configuration files
      echo "Generating configuration files..."
      if [ -f "./sync_config.sh" ]; then
        ./sync_config.sh --force
      else
        echo -e "${YELLOW}Warning: sync_config.sh not found, skipping configuration sync${NORMAL}"
      fi
      
      # Set up CoreDNS for local DNS resolution
      echo "Setting up local DNS resolution..."
      mkdir -p ./coredns/zones
      
      # Create Corefile if it doesn't exist
      if [ ! -f "./coredns/Corefile" ]; then
        cat > "./coredns/Corefile" <<EOF
. {
    forward . 8.8.8.8 8.8.4.4
    cache
}

formr.local:53 {
    file /zones/formr.local.db
    reload 5s
    log
    errors
}
EOF
      fi
      
      # Create zone file
      cat > "./coredns/zones/formr.local.db" <<EOF
\$ORIGIN formr.local.
\$TTL 60
@ IN A 127.0.0.1
* IN A 127.0.0.1
EOF
      
      echo -e "${GREEN}Configuration complete!${NORMAL}"
      
      # Start services
      echo "Starting Docker services..."
      docker compose down
      docker compose up -d
      
      # Verify services are running
      echo "Checking if services are running..."
      sleep 5
      
      if docker compose ps | grep -q "Up"; then
        echo -e "${GREEN}Services are running!${NORMAL}"
      else
        echo -e "${RED}Services failed to start properly.${NORMAL}"
        echo "Please check Docker logs with 'docker compose logs'"
      fi
      
      break
      ;;
      
    "Fix Docker Compose File")
      print_header "Fixing Docker Compose File"
      
      # Run the fix script
      ./fix_compose.sh
      
      echo -e "${GREEN}Docker Compose file has been checked/fixed.${NORMAL}"
      break
      ;;
      
    "Start/Restart Services")
      print_header "Starting Services"
      
      echo "Stopping any running services..."
      docker compose down
      
      echo "Starting services..."
      docker compose up -d
      
      echo "Checking if services are running..."
      sleep 5
      
      if docker compose ps | grep -q "Up"; then
        echo -e "${GREEN}Services are running!${NORMAL}"
        echo "You can access FormR at http://localhost"
      else
        echo -e "${RED}Services failed to start properly.${NORMAL}"
        echo "Please check Docker logs with 'docker compose logs'"
      fi
      
      break
      ;;
      
    "Exit")
      echo "Exiting setup."
      exit 0
      ;;
      
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done

echo -e "\n${BOLD}FormR Setup Complete${NORMAL}"
echo -e "You can access FormR at: ${BOLD}http://localhost${NORMAL}"
echo -e "To check status: ${BOLD}docker compose ps${NORMAL}"
echo -e "To stop services: ${BOLD}docker compose down${NORMAL}"
echo -e "To view logs: ${BOLD}docker compose logs${NORMAL}"
