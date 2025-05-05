#!/usr/bin/env bash
#
# Utility functions for the formr setup scripts
# Includes functions previously in _lib.sh
#

# --- Color Definitions ---
# Check if running in a terminal that supports colors
if [ -t 1 ] && tput colors &> /dev/null; then
  BOLD=$(tput bold)
  NORMAL=$(tput sgr0)
  GREEN=$(tput setaf 2)
  RED=$(tput setaf 1)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
else
  # Fallback for non-interactive or terminals without color support
  BOLD=""
  NORMAL=""
  GREEN=""
  RED=""
  YELLOW=""
  BLUE=""
fi

# --- Logging and Output Functions ---

# Log function for consistent formatting (from _lib.sh)
log() {
    # Consider adding log levels (INFO, WARN, ERROR) later if needed
    printf '%s %s\n' "$(date +'%F %T')" "$*"
}

# Debug function: prints message if the first argument is 'true'
# Usage: debug "true" "Your debug message"
#    or: debug "$DEBUG_VAR" "Your debug message"
debug() {
    local is_debug_enabled="$1"
    shift
    if [ "$is_debug_enabled" = true ]; then
        printf "${RED}[DEBUG] %s${NORMAL}\n" "$*"
    fi
}

print_section() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NORMAL}\n"
}

# --- User Interaction Functions ---

prompt_yn() {
    local prompt_text="$1"
    local default="${2:-y}"
    local force_answer="${3:-}"
    local input

    if [ -n "$force_answer" ]; then
        case "$force_answer" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) input="$default";;
        esac
    elif [ ! -t 0 ]; then
        input="$default"
    fi

    if [ -n "$input" ]; then
        case "$input" in
            [Yy]* ) return 0;;
            * ) return 1;;
        esac
    fi

    while true; do
        read -p "$prompt_text [y/n] (default: $default): " input
        
        # Handle Ctrl+D and other read errors
        if [ $? -ne 0 ]; then
            echo
            return 1
        fi

        # Use default if empty input
        input="${input:-$default}"
        
        case "$input" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}


# Function for option selection
select_from_options() {
    local prompt="$1"
    shift
    local options=("$@")
    local selection
    local default_option_index=0

    echo "$prompt"
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}"
    done

    if [ ! -t 0 ]; then
        return $default_option_index
    fi

    while true; do
        # Handle user input in the main process
        read -p "Select an option (1-${#options[@]}, default: $((default_option_index + 1))): " selection
        
        # Handle Ctrl+D (EOF) and other read errors
        if [ $? -ne 0 ]; then
            echo
            return 255
        fi
        
        # Use default if empty
        selection="${selection:-$((default_option_index + 1))}"
        
        # Validate selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#options[@]}" ]; then
            return $((selection-1))
        else
            echo "Invalid selection. Please enter a number between 1 and ${#options[@]}."
        fi
    done
}

# Function to invoke the default editor for a file
invoke_editor() {
    local file_to_edit="$1"
    if [ -z "$file_to_edit" ] || [ ! -f "$file_to_edit" ]; then
        log "ERROR: File '$file_to_edit' not found or not specified for editing."
        return 1
    fi

    # Use VISUAL or EDITOR environment variable, fallback to nano/vi
    local editor_cmd="${VISUAL:-${EDITOR:-nano}}"
    if ! command -v "$editor_cmd" &>/dev/null; then
        log "Editor '$editor_cmd' not found, trying 'vi'..."
        if command -v vi &>/dev/null; then
            editor_cmd="vi"
        else
            log "ERROR: Cannot find a suitable editor (tried $VISUAL, $EDITOR, nano, vi)."
            return 1
        fi
    fi

    log "Opening '$file_to_edit' with '$editor_cmd'..."
    # Run the editor directly in the current terminal session
    if ! "$editor_cmd" "$file_to_edit"; then
         log "Warning: Editor '$editor_cmd' exited with non-zero status for '$file_to_edit'."
         # Decide if this should be an error (return 1) or just a warning
    fi
    return 0
}


# --- Database Functions (from _lib.sh) ---

# Wait for database to be ready
# Usage: wait_for_db host port user password database
wait_for_db() {
    local tries=30 delay=2 host=$1 port=$2 user=$3 password=$4 db=$5

    log "Waiting for database to be ready at $host:$port..."
    for i in $(seq 1 "$tries"); do
        # Check MARIADB_ROOT_PASSWORD first, then MARIADB_PASSWORD if root fails
        if docker exec formr_db mysql -h"$host" -P"$port" -uroot -p"${MARIADB_ROOT_PASSWORD:-}" -e "USE $db;" &>/dev/null; then
            log "✓ Database is ready! (Checked as root)"
            return 0
        elif docker exec formr_db mysql -h"$host" -P"$port" -u"$user" -p"$password" -e "USE $db;" &>/dev/null; then
             log "✓ Database is ready! (Checked as $user)"
             return 0
        else
            log "Database not ready ($i/$tries). Waiting $delay seconds..."
            sleep "$delay"
        fi
    done

    log "ERROR: Database never became ready after $tries attempts"
    return 1
}

# Execute SQL with fallback authentication
# Usage: execute_sql "SQL COMMAND" [database]
execute_sql() {
    local sql_command="$1"
    local database="${2:-}"
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log "SQL execution attempt $attempt/$max_attempts..."

        # Try root first
        if [ -n "$database" ]; then
            # If database is specified, use it
            if docker exec -i formr_db mysql -hlocalhost -uroot -p"${MARIADB_ROOT_PASSWORD:-}" "$database" <<< "$sql_command" &>/dev/null; then
                log "SQL executed successfully as root in database '$database'."
                return 0
            fi
        else
            # No specific database
            if docker exec -i formr_db mysql -hlocalhost -uroot -p"${MARIADB_ROOT_PASSWORD:-}" <<< "$sql_command" &>/dev/null; then
                 log "SQL executed successfully as root."
                 return 0
            fi
        fi

        # If root fails, try with regular user
        log "Root execution failed, trying with regular user ${MARIADB_USER:-}..."
        if [ -n "$database" ]; then
            if docker exec -i formr_db mysql -hlocalhost -u"${MARIADB_USER:-}" -p"${MARIADB_PASSWORD:-}" "$database" <<< "$sql_command" &>/dev/null; then
                 log "SQL executed successfully as ${MARIADB_USER:-} in database '$database'."
                 return 0
            fi
        else
            if docker exec -i formr_db mysql -hlocalhost -u"${MARIADB_USER:-}" -p"${MARIADB_PASSWORD:-}" <<< "$sql_command" &>/dev/null; then
                 log "SQL executed successfully as ${MARIADB_USER:-}."
                 return 0
            fi
        fi

        log "SQL execution failed on attempt $attempt for both root and ${MARIADB_USER:-}."
        if [ $attempt -eq $max_attempts ]; then
             log "ERROR: All SQL execution attempts failed!"
             return 1
        fi

        attempt=$((attempt+1))
        sleep 2
    done

    return 1 # Should not be reached, but ensures failure return
}

# --- File and System Functions (from _lib.sh) ---

# Ensure a container is running
ensure_container_running() {
    local container="$1"
    local status

    status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "notfound")

    case "$status" in
        "running")
            log "Container $container is already running"
            return 0
            ;;
        "notfound")
            log "Container $container not found, needs to be started"
            return 1 # Indicate action needed
            ;;
        *)
            log "Container $container exists but is not running (status: $status), needs restart"
            return 1 # Indicate action needed
            ;;
    esac
}

# Generate a secure random password
generate_password() {
    # Use /dev/urandom for better portability than openssl if available
    if [ -c /dev/urandom ]; then
         head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16
         echo # Add newline
    elif command -v openssl &> /dev/null; then
         openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16
         echo # Add newline
    else
         log "ERROR: Cannot generate password. Need /dev/urandom or openssl."
         # Return a default or fail? Failing is safer.
         return 1
    fi
    return 0
}
# Function to get the primary local network IP address
get_local_ip() {
    local ip_address=""
    # Try common macOS interfaces first
    ip_address=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)

    # If macOS methods failed, try common Linux methods
    if [ -z "$ip_address" ]; then
        # Try hostname -I (often gives multiple IPs, take the first)
        ip_address=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    if [ -z "$ip_address" ]; then
        # Fallback using ip route (might be more reliable on some Linux systems)
        ip_address=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
    fi

    # Check if we found an IP
    if [ -n "$ip_address" ]; then
        echo "$ip_address"
        return 0
    else
        log "ERROR: Could not automatically determine local IP address."
        # Optionally prompt user here, but for now, just return error
        return 1
    fi
}

# --- Display Functions ---

# Function to display final access options
# This function now determines network setup status and IP itself
display_access_options() {
    local domain=""
    local https_method="noredirect" # Default
    local formr_port="80" # Default

    # Get the domain from .env file, defaulting to localhost if not found
    if [ -f ".env" ]; then
        # Use parameter expansion to avoid errors if grep finds nothing
        domain_line=$(grep -E "^FORMR_DOMAIN=" .env)
        https_method_line=$(grep -E "^HTTPS_METHOD=" .env)

        domain=${domain_line#*=}
        https_method=${https_method_line#*=}
    fi

    # Default to localhost if DOMAIN is empty or not set
    domain=${domain:-localhost}
    https_method=${https_method:-noredirect}

    # Extract the port for formr_app from docker-compose.yml (default to 80 if not found)
    if [ -f "docker-compose.yml" ]; then
         # Be more robust: handle potential errors and different YAML structures
         local port_line=$(awk '/formr_app:/,/^[^[:space:]]/ {if (/ports:/) {p=1; next} if (p && /- "[0-9]+:/) {print $2; exit}}' docker-compose.yml | head -1)
         # Extract number before colon
         local extracted_port=$(echo "$port_line" | grep -o '^[0-9]\+' || echo "")
         formr_port=${extracted_port:-80}
    else
         log "Warning: docker-compose.yml not found. Assuming default port 80."
         formr_port="80"
    fi


    # Construct domain with port
    local domain_with_port=""
    if [[ "$domain" == *":"* ]]; then
        # Domain already includes a port, use as is
        domain_with_port="$domain"
    else
        # Add port based on rules
        # Don't add port 80 for http or port 443 for https (standard ports)
        if [[ "$domain" == "localhost" && "$formr_port" == "80" ]]; then
            domain_with_port="$domain"
        elif [[ "$domain" != "localhost" ]]; then
            # For non-localhost domains, include port unless it's standard for the protocol
             local protocol="http" # Determine protocol first
             if [[ "$https_method" == "redirect" || "$https_method" == "https_only" ]]; then # Assuming https_only might be another option
                  protocol="https"
             fi

             if [[ "$protocol" == "http" && "$formr_port" == "80" ]] || [[ "$protocol" == "https" && "$formr_port" == "443" ]]; then
                  domain_with_port="$domain"
             else
                  domain_with_port="${domain}:${formr_port}"
             fi
        else
            # For localhost with non-standard port, include port
            domain_with_port="${domain}:${formr_port}"
        fi
    fi

    # Determine protocol
    local protocol="http"
    # Always use http for localhost unless HTTPS is explicitly forced somehow?
    # For simplicity, stick to http for localhost for now.
    if [[ "$domain" != "localhost"* ]]; then
         # Use https if method is redirect or https_only
         if [[ "$https_method" == "redirect" || "$https_method" == "https_only" ]]; then
              protocol="https"
         fi
    fi


    echo -e "\n${BOLD}Access Options:${NORMAL}"
    echo "• Local browser: ${BOLD}${protocol}://${domain_with_port}${NORMAL}"
    # Assume formr.local always uses http unless CoreDNS/proxy handles HTTPS?
    # For now, keep it simple. If CoreDNS setup implies HTTPS, adjust this.
    echo "• Local network (via DNS): ${BOLD}http://formr.local${NORMAL} (if CoreDNS is set up)"


    # Display network access information if HTTPS setup seems complete
    # Check for existence of certs or Apache SSL config as indicators
    local cert_file="./certs/formr.cert.pem"
    local key_file="./certs/formr.key.pem"
    local apache_ssl_conf="./formr_app/apache/sites-enabled/formr-ssl.conf"
    local network_setup_likely_done=false
    local server_ip_local=""

    if [ -f "$cert_file" ] && [ -f "$key_file" ] && [ -f "$apache_ssl_conf" ]; then
        network_setup_likely_done=true
        # Attempt to get the local IP address
        server_ip_local=$(get_local_ip)
        # Check if get_local_ip succeeded
        if [ $? -ne 0 ] || [ -z "$server_ip_local" ]; then
             log "Warning: HTTPS setup seems complete, but could not determine local IP for access instructions."
             server_ip_local="" # Ensure it's empty if detection failed
        fi
    fi

    if [ "$network_setup_likely_done" = true ] && [ -n "$server_ip_local" ]; then
        echo -e "\n${BOLD}Network Access (using IP - HTTPS):${NORMAL}"
        echo "• Direct IP Access: ${BOLD}https://${server_ip_local}${NORMAL} (may show browser warning if self-signed)"
        # The local.formr domain might require manual host file setup, mention this clearly
        echo "• Optional Domain: ${BOLD}https://local.formr${NORMAL} (requires manual hosts file setup on client devices)"
        if [ -f "./formr_access_instructions.md" ]; then
             echo -e "  See ${BOLD}formr_access_instructions.md${NORMAL} for details."
        fi
    elif [ "$network_setup_likely_done" = true ]; then
         # If setup seems done but IP failed
         echo -e "\n${YELLOW}Network HTTPS setup appears complete, but failed to determine your local IP.${NORMAL}"
         echo "You might need to find your machine's IP address manually to access via HTTPS from other devices."
    fi

    echo -e "\n${BOLD}Management Commands:${NORMAL}"
    echo "• Status: docker compose ps"
    echo "• Logs:   docker compose logs -f [service_name]"
    echo "• Stop:   docker compose down"
    echo "• Start:  docker compose up -d"
}