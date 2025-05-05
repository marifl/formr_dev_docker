#!/usr/bin/env bash
#
# Helper functions for CoreDNS setup in cli_setup_wrapper.sh
#

# Note: This script expects helper functions like print_section,
# and color variables (GREEN, YELLOW, RED, NORMAL) to be defined in the
# calling script (cli_setup_wrapper.sh) or sourced from utils.sh before
# sourcing this file.

# Setup CoreDNS configuration for dynamic IP routing
setup_coredns_config() {
    # Returns 0 on success, 1 on failure to create files/dirs

    print_section "Setting up CoreDNS for dynamic IP routing"

    local coredns_dir="./coredns"
    local zones_dir="$coredns_dir/zones"
    local corefile="$coredns_dir/Corefile"
    local zonefile="$zones_dir/formr.local.db"

    # Create directories if they don't exist
    if ! mkdir -p "$zones_dir"; then
         echo -e "${RED}Error: Failed to create directory $zones_dir${NORMAL}"
         return 1
    fi
    echo "Ensured directory exists: $zones_dir"

    # Create Corefile if it doesn't exist
    if [ ! -f "$corefile" ]; then
        echo "Creating CoreDNS configuration file ($corefile)..."
        cat > "$corefile" <<EOF
. {
    forward . 8.8.8.8 8.8.4.4 # Default forwarders (e.g., Google DNS)
    cache 30                # Cache DNS responses for 30 seconds
    errors                  # Log errors
}

formr.local:53 {
    file /etc/coredns/zones/formr.local.db # Path inside the container
    reload 5s           # Check for zone file changes every 5 seconds
    log                 # Enable query logging for this zone
    errors              # Log errors for this zone
}
EOF
        if [ $? -eq 0 ]; then
             echo -e "${GREEN}Created CoreDNS configuration file: $corefile${NORMAL}"
        else
             echo -e "${RED}Error: Failed to create Corefile: $corefile${NORMAL}"
             return 1
        fi
    else
        echo -e "${GREEN}CoreDNS configuration file already exists: $corefile${NORMAL}"
    fi

    # Create initial zone file (overwrite if exists to ensure default content)
    echo "Creating/Updating initial zone file ($zonefile)..."
    cat > "$zonefile" <<EOF
\$ORIGIN formr.local.
\$TTL 60 ; 1 minute default TTL
@       IN SOA  localhost. root.localhost. (
                $(date +%Y%m%d%H) ; Serial YYYYMMDDHH
                60         ; Refresh (1 minute)
                60         ; Retry (1 minute)
                604800     ; Expire (1 week)
                60 )       ; Negative Cache TTL (1 minute)
        IN NS   localhost. ; Define the nameserver (can be arbitrary for local setup)
        IN A    127.0.0.1  ; Default IP for formr.local
*       IN A    127.0.0.1  ; Default IP for *.formr.local (wildcard)
EOF
    if [ $? -eq 0 ]; then
         echo -e "${GREEN}Created/Updated initial zone file: $zonefile${NORMAL}"
    else
         echo -e "${RED}Error: Failed to create zone file: $zonefile${NORMAL}"
         return 1
    fi

    echo -e "${GREEN}CoreDNS configuration complete!${NORMAL}"
    echo "Docker Compose needs to mount $coredns_dir/Corefile to /etc/coredns/Corefile"
    echo "and $zones_dir to /etc/coredns/zones inside the CoreDNS container."
    echo "The host-ip-updater service will manage dynamic updates to the zone file."
    return 0
}