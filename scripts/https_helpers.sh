#!/usr/bin/env bash
#
# Helper functions for HTTPS setup in cli_setup_wrapper.sh
#

# Note: This script expects helper functions like print_section, select_from_options, prompt_yn,
# and color variables (GREEN, YELLOW, RED, NORMAL, BOLD) to be defined in the
# calling script (cli_setup_wrapper.sh) before sourcing this file.
# It also expects SERVER_IP and NETWORK_SETUP_DONE to be accessible (passed or global).

# Function to setup locally trusted HTTPS using mkcert
setup_local_trusted_https() {
    # Returns 0 on success, 1 on failure.
    # The function now determines the IP itself using get_local_ip from utils.sh
    # It passes the determined IP back to the main setup function if needed via SERVER_IP global (for now).

    print_section "Setting up trusted HTTPS certificates"
    echo "This will install locally trusted certificates using mkcert."

    # Check if mkcert is installed
    if ! command -v mkcert &> /dev/null; then
        echo "mkcert not found. Attempting to install using brew..."
        if ! command -v brew &> /dev/null; then
             echo -e "${RED}Error: Homebrew (brew) not found. Cannot install mkcert automatically.${NORMAL}"
             echo "Please install mkcert manually (see https://github.com/FiloSottile/mkcert) and run this script again."
             return 1
        fi
        echo "Installing mkcert and nss..."
        if ! brew install mkcert nss; then
             echo -e "${RED}Error: Failed to install mkcert or nss via brew.${NORMAL}"
             return 1
        fi
        echo "Running mkcert -install..."
        if ! mkcert -install; then
             echo -e "${RED}Error: mkcert -install failed. You might need to run it manually with sudo.${NORMAL}"
             return 1
        fi
        echo -e "${GREEN}mkcert installed and local CA configured successfully.${NORMAL}"
    else
        echo "mkcert is already installed."
        # Ensure the local CA is installed, run install again just in case
        if ! mkcert -install; then
             echo -e "${RED}Error: mkcert -install failed. Local CA might not be properly installed.${NORMAL}"
             # Decide if this is fatal or just a warning
             # return 1
        fi

    fi

    # Create directory for certificates if it doesn't exist
    mkdir -p ./certs
    chmod 755 ./certs

    # Get the local IP address using the utility function
    local local_ip
    local_ip=$(get_local_ip)
    if [ $? -ne 0 ] || [ -z "$local_ip" ]; then
        echo -e "${RED}Failed to determine local IP address.${NORMAL}"
        # Optionally prompt user for IP as a fallback
        read -p "Please enter your local network IP address manually: " local_ip
        if [ -z "$local_ip" ]; then
             echo -e "${RED}Error: IP address is required for certificate generation.${NORMAL}"
             return 1
        fi
        echo "Using manually entered IP: $local_ip"
    else
         echo "Using automatically detected local IP: $local_ip"
    fi


    echo "Generating trusted certificates for ${local_ip}, formr.local, and localhost..."
    # Generate certs in the ./certs directory
    if ! mkcert -key-file ./certs/formr.key.pem -cert-file ./certs/formr.cert.pem "${local_ip}" "formr.local" "localhost" "127.0.0.1"; then
         echo -e "${RED}Failed to generate certificates using mkcert!${NORMAL}"
         return 1
    fi

    # Verify certificates were created
    if [ -f "./certs/formr.cert.pem" ] && [ -f "./certs/formr.key.pem" ]; then
        echo -e "${GREEN}Certificates generated successfully in ./certs/${NORMAL}"
    else
        echo -e "${RED}Failed to find generated certificates!${NORMAL}"
        return 1
    fi

    # Set permissions
    chmod 644 ./certs/formr.cert.pem
    chmod 600 ./certs/formr.key.pem

    # Create Apache SSL configuration
    mkdir -p ./formr_app/apache/sites-enabled
    cat > ./formr_app/apache/sites-enabled/formr-ssl.conf << EOF
<VirtualHost *:443>
    ServerName formr.local
    ServerAlias ${local_ip} localhost 127.0.0.1 # Use the determined local_ip
    DocumentRoot /formr/formr/webroot

    SSLEngine on
    # Paths inside the container where certs will be mounted
    SSLCertificateFile /etc/ssl/certs/formr.cert.pem
    SSLCertificateKeyFile /etc/ssl/private/formr.key.pem

    <Directory /formr/formr/webroot>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    # Optional: Add headers for security
    # Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
</VirtualHost>
EOF
    echo -e "${GREEN}Apache SSL configuration created (./formr_app/apache/sites-enabled/formr-ssl.conf).${NORMAL}"
    echo -e "${BOLD}Trusted HTTPS setup complete!${NORMAL}"
    echo "Docker Compose needs to mount ./certs to /etc/ssl/certs and /etc/ssl/private in the Apache container."
    echo "Your browser should now trust the certificates for formr.local and ${local_ip}."

    # Indicate network setup was done for the final message
    # Still using global for simplicity in this refactor step, could be improved later
    export NETWORK_SETUP_DONE=true
    # Update SERVER_IP if it wasn't set before, using the determined local_ip
    if [ -z "$SERVER_IP" ]; then
        export SERVER_IP="$local_ip"
    fi
    # Remove the export of CERT_IP_ADDRESS as it's no longer needed globally
    unset CERT_IP_ADDRESS # Ensure it's not lingering if it was set before

    return 0
}

# Function to setup self-signed HTTPS using existing script
setup_self_signed_https() {
    # Expects SERVER_IP and NETWORK_SETUP_DONE to be accessible (passed or global).
    # Returns 0 on success, 1 on failure.

    print_section "Setting up self-signed HTTPS"

    if [ -f "./setup_local_network.sh" ]; then
        echo "Running ./setup_local_network.sh for self-signed certificates..."
        chmod +x ./setup_local_network.sh
        if ! ./setup_local_network.sh; then
             echo -e "${RED}Error running ./setup_local_network.sh${NORMAL}"
             return 1
        fi

        # Set variables for displaying network access options later
        if [ -f "./formr_access_instructions.md" ]; then
            export NETWORK_SETUP_DONE=true
            # Try to extract the IP address from the instructions file
            local extracted_ip=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' ./formr_access_instructions.md | head -1)
            if [ -n "$extracted_ip" ]; then
                 export SERVER_IP="$extracted_ip"
                 echo "Extracted SERVER_IP from instructions: $SERVER_IP"
            else
                 echo -e "${YELLOW}Could not extract IP address from formr_access_instructions.md${NORMAL}"
            fi
            echo -e "${GREEN}Self-signed certificate setup complete (via setup_local_network.sh).${NORMAL}"
            echo -e "${YELLOW}Users will see browser security warnings.${NORMAL}"
            return 0
        else
            echo -e "${YELLOW}Warning: formr_access_instructions.md not found after running setup_local_network.sh.${NORMAL}"
            # Assume setup might have worked but can't confirm IP
            export NETWORK_SETUP_DONE=true # Set anyway? Or handle as failure?
            return 1 # Treat as failure if instructions are missing
        fi
    else
        echo -e "${RED}Error: setup_local_network.sh script not found.${NORMAL}"
        echo -e "Cannot set up self-signed certificates automatically."
        return 1
    fi
}

# Main function to handle Step 6: HTTPS Setup
# Note: restart_containers function moved to docker_helpers.sh
setup_https_access() {
    # Expects SERVER_IP and NETWORK_SETUP_DONE to be accessible (passed or global).
    # Returns 0 if setup is done (or skipped), 1 on failure.

    print_section "Step 6: Local Network HTTPS Access"
    echo -e "This step configures FormR for access from other devices on your local network via HTTPS."
    echo -e "Options:"
    echo -e "1. Trusted certificates (recommended, no browser warnings, requires mkcert)"
    echo -e "2. Self-signed certificates (users will see browser warnings)"

    local https_mode_choice
    select_from_options "Select HTTPS setup method:" "Trusted certificates (recommended)" "Self-signed certificates (with warnings)" "Skip HTTPS setup"
    https_mode_choice=$?

    local setup_success=false
    case $https_mode_choice in
        0) # Trusted certificates
            if setup_local_trusted_https; then
                 setup_success=true
            else
                 echo -e "${RED}Trusted HTTPS setup failed.${NORMAL}"
                 # Ask user if they want to fallback or exit?
                 if prompt_yn "Trusted setup failed. Try self-signed setup instead?"; then
                      if setup_self_signed_https; then
                           setup_success=true
                      else
                           echo -e "${RED}Self-signed HTTPS setup also failed.${NORMAL}"
                      fi
                 fi
            fi
            ;;
        1) # Self-signed certificates
            if setup_self_signed_https; then
                 setup_success=true
            else
                 echo -e "${RED}Self-signed HTTPS setup failed.${NORMAL}"
            fi
            ;;
        2) # Skip
            echo "Skipping HTTPS setup."
            echo -e "${YELLOW}FormR might only be accessible via HTTP or on localhost.${NORMAL}"
            return 0 # Return success as user chose to skip
            ;;
        *)
            echo -e "${RED}Invalid selection.${NORMAL}"
            return 1
            ;;
    esac

    # Restart containers only if a setup method was successfully completed
    if [ "$setup_success" = true ]; then
        echo -e "${GREEN}HTTPS configuration generated.${NORMAL}"
        if prompt_yn "Restart Docker containers now to apply HTTPS changes?"; then
            if ! restart_containers; then
                 echo -e "${RED}Failed to restart containers. Please restart manually ('docker compose down && docker compose up -d').${NORMAL}"
                 return 1 # Indicate failure if restart fails
            fi
            echo -e "${GREEN}Containers restarted successfully.${NORMAL}"
        else
            echo -e "${YELLOW}Skipped container restart. HTTPS changes will not be active until containers are restarted.${NORMAL}"
        fi
        return 0 # Indicate success
    else
        echo -e "${RED}HTTPS setup was not completed successfully.${NORMAL}"
        return 1 # Indicate failure
    fi
}