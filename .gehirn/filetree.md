# Project Filetree (Relevant for formr.local HTTP setup)

```
.
├── .gehirn/
│   ├── tasks/
│   │   ├── 2025-05-03-22-24-54_configure_formr_local.md  # Initial task list (superseded)
│   │   ├── 2025-05-03-22-39-39_formr_local_docker_plan.md # Approved plan (updated for HTTP)
│   │   ├── 2025-05-05-13-30-00_dns_network_investigation.md # DNS network investigation
│   │   ├── 2025-05-05-13-38-19_hostname_caching_investigation.md # Hostname caching investigation
│   │   ├── 2025-05-05-13-57-01_connectivity_diagnosis.md # Connectivity diagnosis
│   │   ├── 2025-05-05-14-30-00_default_user_password_mismatch.md # Default user password mismatch
│   │   ├── 2025-05-05-14-38-00_fix_default_admin_user_creation.md # Fix for default admin user creation
│   │   └── 2025-05-05-15-13-06_spreadsheet_reader_error.md # SpreadsheetReader PHP intl extension fix
│   ├── 2025-05-03-22-41-39_changelog.md             # Changelog for HTTP setup
│   ├── 2025-05-05-14-39-00_changelog.md             # Changelog for MariaDB client fix
│   ├── 2025-05-05-15-16-03_changelog.md             # Changelog for PHP intl extension fix
│   └── filetree.md                                  # This file (updated for HTTP)
├── dnsmasq.conf                  # Configuration for dnsmasq container
├── traefik.yml                   # Configuration for traefik container (HTTP only)
├── docker-compose.yml            # Main Docker Compose file (modified for HTTP & dnsmasq ARM64 fix - attempt 2)
├── formr_app/
│   ├── apache/
│   │   └── sites-enabled/
│   │       └── formr.conf        # Apache site config (modified for HTTP)
│   ├── Dockerfile               # Modified to include PHP intl extension
│   └── ... (other formr_app files)
├── mysql/
│   └── ... (mysql files)
├── opencpu/
│   └── ... (opencpu files)
├── php_daemon/
│   └── ... (php_daemon files)
├── README.md                    # Project documentation and requirements
└── ... (other project root files)

```

**Notes:**

*   This tree focuses on files directly modified or added for the `http://formr.local` setup with Traefik and dnsmasq.
*   The previous requirement for a `certs` directory and `mkcert` setup has been removed as we are now using HTTP only.
*   The Dockerfile has been modified to include PHP intl extension for proper spreadsheet handling.