#!/usr/bin/env bash
#
# Helper functions for Docker operations in cli_setup_wrapper.sh
#

# Note: This script expects helper functions like print_section, prompt_yn,
# and color variables (GREEN, YELLOW, RED, NORMAL) to be defined in the
# calling script (cli_setup_wrapper.sh) before sourcing this file.

# Function to check if Docker containers are running
check_containers_running() {
    local max_attempts=${1:-3} # Default to 3 attempts if not provided
    local attempt=1
    local wait_time=5

    echo "Checking if containers are running..."

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..."

        # Get running containers count that are part of this compose project
        # Ensure wc returns a number even if empty
        local running_count=$(docker compose ps -q --filter "status=running" 2>/dev/null | wc -l | tr -d ' ' | awk '{print $1+0}')
        local expected_count=$(docker compose config --services 2>/dev/null | wc -l | tr -d ' ' | awk '{print $1+0}')

        # Handle case where expected_count might be zero or command fails
        if [ -z "$expected_count" ] || ! [[ "$expected_count" =~ ^[0-9]+$ ]]; then
             echo -e "${RED}Error determining expected container count. Cannot verify status.${NORMAL}"
             docker compose config --services # Show potential error message
             return 1
        fi

        if [ "$running_count" -eq "$expected_count" ] && [ "$expected_count" -gt 0 ]; then
            echo -e "${GREEN}All containers ($running_count/$expected_count) are running!${NORMAL}"
            return 0
        elif [ "$running_count" -gt 0 ]; then
            echo -e "${YELLOW}Only $running_count/$expected_count containers are running.${NORMAL}"
        else
            if [ "$expected_count" -eq 0 ]; then
                echo -e "${GREEN}No services defined in compose file. Nothing to run.${NORMAL}"
                return 0
            else
                echo -e "${RED}No containers are running! (Expected: $expected_count)${NORMAL}"
                # Show container logs for debugging
                echo -e "\n${YELLOW}Container logs:${NORMAL}"
                for service in $(docker compose config --services); do
                    echo -e "\n${YELLOW}=== $service logs ===${NORMAL}"
                    docker compose logs --tail=20 "$service"
                done
            fi
        fi

        # Show container status
        echo -e "\n${YELLOW}Container status:${NORMAL}"
        docker compose ps

        # If not on final attempt, wait and retry
        if [ $attempt -lt $max_attempts ]; then
            echo "Waiting $wait_time seconds before next check..."
            sleep $wait_time
        fi

        attempt=$((attempt+1))
    done

    echo -e "${RED}Failed to confirm all containers are running after $max_attempts attempts.${NORMAL}"
    return 1
}

# Function to retry build if it fails
retry_build() {
    print_section "Container Startup Retry"
    echo -e "${YELLOW}Attempting to fix container startup issues...${NORMAL}"

    # Show container logs for debugging
    echo "Recent container logs:"
    docker compose logs --tail=20

    # Try to fix common issues
    if prompt_yn "Would you like to try restarting the containers?"; then
        echo "Stopping all containers..."
        docker compose down || echo -e "${YELLOW}Warning: \'docker compose down\' failed. Proceeding anyway.${NORMAL}"
        echo "Starting containers again..."
        docker compose up -d

        if check_containers_running 3; then
            echo -e "${GREEN}Successfully started containers on retry!${NORMAL}"
            return 0
        fi
    fi

    echo -e "${RED}Container startup issues persist. Please check logs for more details:${NORMAL}"
    echo "- Run 'docker compose logs' to see detailed logs"
    echo "- Check your configuration files for errors"
    echo "- Ensure ports are not already in use"
    return 1
}


# Function to validate and fix Docker Compose configuration
validate_docker_compose() {
    print_section "Validating Docker Compose Configuration"

    local compose_file="docker-compose.yml"

    if [ ! -f "$compose_file" ]; then
        echo -e "${RED}Error: $compose_file not found!${NORMAL}"
        return 1
    fi

    # First, check if the config is already valid
    if docker compose config >/dev/null 2>&1; then
        echo -e "${GREEN}Docker Compose configuration is already valid.${NORMAL}"
        return 0
    fi

    echo -e "${YELLOW}Docker Compose configuration seems invalid. Attempting automatic fixes...${NORMAL}"
    echo "Checking Docker Compose file for common issues..."

    # Try the Python script first (more reliable for YAML parsing)
    if [ -f "./fix_docker_compose.py" ] || [ -x "$(command -v python3)" ] || [ -x "$(command -v python)" ]; then
        echo "Using Python to fix Docker Compose format issues..."

        # Create the Python script if it doesn't exist
        if [ ! -f "./fix_docker_compose.py" ]; then
            cat > ./fix_docker_compose.py <<'EOF'
#!/usr/bin/env python3
"""
Fix Docker Compose configuration issues.
Specifically targets the services.host-ip-updater.depends_on.0 format error.
"""

import sys
import yaml
import os

def fix_depends_on_format(yaml_file):
    """
    Fix the host-ip-updater depends_on format from numeric indices to string list.
    """
    print(f"Reading Docker Compose file: {yaml_file}")

    # Create a backup of the original file
    backup_file = f"{yaml_file}.bak_py_fix" # Use a distinct backup name
    try:
        os.system(f"cp {yaml_file} {backup_file}")
        print(f"Created backup at {backup_file}")
    except Exception as e:
        print(f"Error creating backup: {e}")
        return False

    try:
        # Load the YAML file
        with open(yaml_file, 'r') as f:
            # Use load with Loader=yaml.FullLoader or yaml.UnsafeLoader if safe_load fails on complex tags
            try:
                docker_compose = yaml.safe_load(f)
            except yaml.YAMLError:
                print("safe_load failed, trying FullLoader...")
                f.seek(0) # Reset file pointer
                docker_compose = yaml.load(f, Loader=yaml.FullLoader)


        fixed = False
        # Check if the file has services and host-ip-updater
        if isinstance(docker_compose, dict) and 'services' in docker_compose and isinstance(docker_compose['services'], dict) and 'host-ip-updater' in docker_compose['services']:
            service = docker_compose['services']['host-ip-updater']

            # Check if depends_on exists and needs fixing
            if isinstance(service, dict) and 'depends_on' in service and isinstance(service['depends_on'], dict):
                print("Found numeric depends_on format that needs fixing")

                # Convert from dict with numeric keys to list
                deps = service['depends_on']
                deps_list = []

                # Sort by numeric keys if present, otherwise just take values
                try:
                    numeric_keys = sorted([int(k) for k in deps.keys() if str(k).isdigit()])
                    for key in numeric_keys:
                        deps_list.append(deps[key])
                except (ValueError, TypeError):
                    # If keys aren't numeric or mixed, just take values
                    deps_list = list(deps.values())

                # Replace the dict with a list
                service['depends_on'] = deps_list
                print(f"Fixed depends_on format: {deps_list}")
                fixed = True

            else:
                print("depends_on section not found or already in correct format")
        else:
            print("host-ip-updater service or services section not found/invalid in Docker Compose file")

        # Save the updated file only if changes were made
        if fixed:
            with open(yaml_file, 'w') as f:
                yaml.dump(docker_compose, f, default_flow_style=False, sort_keys=False)
            print(f"Updated {yaml_file} with fixed depends_on format")
            return True
        else:
            # No fix needed or possible via this method
            print("No changes made by Python script.")
            # Clean up backup if no changes were made
            os.remove(backup_file)
            print(f"Removed unused backup {backup_file}")
            return False # Indicate no fix was applied, even if no error occurred

    except Exception as e:
        print(f"Error fixing Docker Compose file: {e}")
        # Restore backup in case of error
        try:
            os.system(f"cp {backup_file} {yaml_file}")
            print(f"Restored original file from backup {backup_file}")
        except Exception as restore_e:
             print(f"Error restoring backup: {restore_e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 fix_docker_compose.py <docker-compose.yml>")
        sys.exit(1)

    success = fix_depends_on_format(sys.argv[1])
    # Exit code 0 means fix applied successfully, 1 means error or no fix applied
    sys.exit(0 if success else 1)
EOF
            chmod +x ./fix_docker_compose.py
            echo "Created fix_docker_compose.py script"
        fi

        # Try running with python3 first, then fallback to python if needed
        local python_cmd="python"
        if command -v python3 &>/dev/null; then
            python_cmd="python3"
        elif ! command -v python &>/dev/null; then
             echo -e "${RED}Error: Neither python3 nor python found. Cannot run fix script.${NORMAL}"
             return 1 # Indicate failure
        fi

        echo "Running: $python_cmd ./fix_docker_compose.py \"$compose_file\""
        if $python_cmd ./fix_docker_compose.py "$compose_file"; then
             echo "Python script executed successfully (may or may not have applied fixes)."
             # Check if the config is valid *now*
             if docker compose config >/dev/null 2>&1; then
                 echo -e "${GREEN}Python script fixed the Docker Compose configuration!${NORMAL}"
                 return 0 # Success
             else
                 echo -e "${YELLOW}Python script ran, but config is still invalid. Trying other methods...${NORMAL}"
             fi
        else
             echo -e "${YELLOW}Python script failed or did not apply fixes. Trying other methods...${NORMAL}"
        fi
    else
         echo -e "${YELLOW}Python not found or fix_docker_compose.py missing. Skipping Python-based fix.${NORMAL}"
    fi

    # If Python approach fails or is skipped, try direct manual edit approach (less reliable)
    echo "Trying direct text replacement fix for depends_on format..."

    # Check if the specific problematic pattern exists
    # Look for 'depends_on:' followed by lines starting with spaces and '0:', '1:', etc.
    if grep -Pzq 'host-ip-updater:\s+depends_on:\s+[0-9]:' "$compose_file"; then
        echo "Found potential numeric depends_on format. Attempting direct fix..."

        # Create a backup of the file before making changes
        local backup_file_manual="${compose_file}.manual_bak"
        echo "Creating backup of $compose_file as $backup_file_manual"
        cp "$compose_file" "$backup_file_manual"

        # Use awk to perform the replacement specifically within the host-ip-updater service block
        local awk_script_file=$(mktemp /tmp/fix_depends_on.awk.XXXXXX)
        cat <<'EOF_AWK_FILE' > "$awk_script_file"
/host-ip-updater:/ { in_service=1 }
/^[^ ]/ { if (in_service) { in_service=0; in_depends=0 } } # Reset on non-indented line
in_service && /depends_on:/ { in_depends=1; print; next }
in_service && in_depends && /^[[:space:]]+[0-9]+:/ {
    # Extract the service name after the colon, trim whitespace
    match($0, /:[[:space:]]*(.*)/, arr);
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[1]); # Trim leading/trailing whitespace
    print "    - " arr[1]; # Print in list format
    next;
}
in_service && in_depends && !/^[[:space:]]+[0-9]+:/ { in_depends=0 } # End of depends_on block if line doesn't match pattern
{ print } # Print all other lines
EOF_AWK_FILE

        awk -f "$awk_script_file" "$backup_file_manual" > "$compose_file"

        rm "$awk_script_file"

        echo "Applied direct text replacement to fix depends_on format."

        # Check if the fix worked
        if docker compose config >/dev/null 2>&1; then
            echo -e "${GREEN}Manual text replacement fix was successful!${NORMAL}"
            return 0
        else
            echo -e "${RED}Manual text replacement fix did not resolve the issue. Restoring backup.${NORMAL}"
            cp "$backup_file_manual" "$compose_file" # Restore original
        fi
    else
        echo "Specific numeric depends_on pattern not found for host-ip-updater. Skipping manual text fix."
    fi


    # If all automatic methods fail, offer manual editing
    echo -e "${RED}Automatic fixes were not successful.${NORMAL}"
    echo "The common error is: services.host-ip-updater.depends_on.0 must be a string"
    echo "This usually means the format needs changing from:"
    echo "  depends_on:"
    echo "    0: service_name"
    echo "to:"
    echo "  depends_on:"
    echo "    - service_name"
    echo ""
    if prompt_yn "Would you like to edit '$compose_file' manually now?"; then
        # Use the invoke_editor function from utils.sh
        invoke_editor "$compose_file"

        # Check if the manual edit fixed the issue
        if docker compose config >/dev/null 2>&1; then
            echo -e "${GREEN}Docker Compose configuration is now valid after manual edit!${NORMAL}"
            return 0
        else
            echo -e "${RED}Configuration still has issues after manual editing.${NORMAL}"
            return 1
        fi
    else
        echo -e "${RED}Docker Compose validation failed. Please fix '$compose_file' manually.${NORMAL}"
        return 1
    fi
}
build_and_launch_docker() {
    echo "Starting Docker build and launch process..."

    # Validate Docker Compose configuration
    if ! validate_docker_compose; then
        echo -e "${RED}Docker Compose configuration is invalid and could not be fixed automatically.${NORMAL}"
        return 1
    fi

    # Try docker compose up directly with build flag
    echo "Building and starting containers..."
    if ! docker compose up -d --build; then
        echo -e "${RED}Failed to build and start containers.${NORMAL}"
        return 1
    fi

    # Verify containers are running
    echo "Verifying container status..."
    if ! check_containers_running 3; then
        if ! retry_build; then
            echo -e "${RED}Failed to start containers even after retry.${NORMAL}"
            return 1
        fi
    fi

    echo -e "${GREEN}Docker environment built and launched successfully!${NORMAL}"
    return 0
}
# Function to restart containers (moved from https_helpers.sh)
restart_containers() {
    echo "Restarting Docker containers..."
    
    # Stop containers if they're running
    if docker compose ps -q >/dev/null 2>&1; then
        echo "Stopping containers..."
        if ! docker compose down -v --remove-orphans; then
            echo -e "${RED}Error during 'docker compose down'. Some resources might remain.${NORMAL}"
            if ! prompt_yn "Continue anyway?" "n"; then
                return 1
            fi
        fi
    fi
    
    # Start containers
    echo "Starting containers..."
    if ! docker compose up -d; then
        echo -e "${RED}Failed to start containers.${NORMAL}"
        return 1
    fi

    # Verify containers are running
    echo "Verifying container status..."
    if ! check_containers_running 3; then
        echo -e "${RED}Failed to verify containers are running properly.${NORMAL}"
        return 1
    fi

    echo -e "${GREEN}Containers restarted successfully.${NORMAL}"
    return 0
}