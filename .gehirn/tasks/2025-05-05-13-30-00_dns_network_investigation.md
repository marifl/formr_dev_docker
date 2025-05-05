# DNS and Network Configuration Investigation

## Objectives
- [x] Examine CoreDNS configuration
- [x] Check Docker network setup
- [x] Review environment-specific configurations
- [x] Verify local DNS resolution
- [x] Investigate potential network isolation issues
- [x] Diagnose styling and asset loading problems
- [x] Apply fix for asset loading

## Findings

### CoreDNS Configuration
- Corefile (/coredns/Corefile):
  - Default DNS forwarding to Google DNS (8.8.8.8, 8.8.4.4)
  - Caching enabled
  - Specific configuration for formr.local domain on port 53
  - Zone file loaded from /zones/formr.local.db
  - Logging and error reporting enabled

### Zone File (/coredns/zones/formr.local.db)
- Domain: formr.local
- Nameserver: localhost
- Default IP: 127.0.0.1 for both root domain and wildcard subdomains
- Short TTL (60 seconds) for local development
- Wildcard (*) record points to 127.0.0.1

### Docker Network Configuration
- Single Docker network named "all"
- Network driver: bridge
- All services (formr_app, formr_db, formrmailqueue, formrsessionqueue, opencpu) connected to this network
- Exposed ports:
  - formr_app: 80 (HTTP), 443 (HTTPS)
  - formr_db: 3306 (MySQL)
  - opencpu: 8080 (HTTP)

### Environment Configuration (.env.example)
- Domain Configurations:
  - MAIN_DOMAIN=localhost
  - FORMR_DOMAIN=localhost
  - OPENCPU_DOMAIN=localhost:8080
- HTTPS Method: Redirect
- Timezone: Europe/Berlin

### Local DNS Resolution (/etc/hosts)
- Standard localhost entries:
  - 127.0.0.1 localhost
  - ::1 localhost
- Custom entry:
  - 127.0.0.1 formr.local

### Apache Configuration Analysis
- Virtual Host Configuration (/formr_app/apache/sites-enabled/formr.conf):
  - ServerName: formr.local
  - ServerAlias: localhost
  - DocumentRoot: /formr/webroot
  - Asset Serving:
    - Alias for /assets/ directory
    - XSendFile enabled for downloads
    - Rewrite rules to handle static and dynamic content
  - HTTP to HTTPS redirect for formr.local and localhost

### Asset Loading Diagnosis
- `curl` test to `https://localhost/assets/css/main.css` returned 200 OK but with `Content-Type: text/html`, indicating the asset was not served directly.
- `docker exec formr_app ls -l /formr/webroot/assets/css/` failed with "No such file or directory", confirming the asset path does not exist in the container.

## Root Cause Identified

The primary issue was that the application files, including the webroot and assets, were not being correctly mounted into the `formr_app` container. The `docker-compose.yml` file specified a volume mount from `./formr_app/formr` on the host to `/formr` in the container. However, the directory `./formr_app/formr` did not exist on the host based on the provided file structure.

This prevented Apache from finding and serving the static assets (CSS, etc.) from `/formr/webroot/assets/`, causing requests for these files to fall through to the index.php, resulting in the unstyled website.

## Applied Solution

Corrected the volume mount in `docker-compose.yml` to point to the actual directory on the host that contains the application's webroot and assets. The volume mount was changed from:
`- ./formr_app/formr:/formr`
to:
`- ./formr_app:/formr`

This change should now mount the contents of the `./formr_app` directory on the host to the `/formr` directory inside the container, making the `webroot/assets/` path available to Apache.

## Verification

To verify the fix, please rebuild and restart your Docker containers and then check if the website styling is correctly applied.