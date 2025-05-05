# formr Development Environment Setup (Apple Silicon)

This guide provides instructions for setting up the formr development environment on Apple Silicon (M1/M2) Macs using Docker.

## System Requirements

- macOS running on Apple Silicon (M1/M2)
- Docker Desktop for Apple Silicon
- Git

## PHP Extensions & Dependencies

The following PHP extensions are required and installed in the Docker container:

- gd (Image processing)
- mysqli (MySQL database connectivity)
- pdo/pdo_mysql (Database abstraction)
- zip (File compression)
- soap (SOAP web services)
- intl (Internationalization)
- xml (XML processing)

Dependencies for these extensions:
- libfreetype6-dev (for GD)
- libjpeg62-turbo-dev (for GD)
- libicu-dev (for Intl)
- libpng-dev (for GD)
- libzip-dev (for ZIP)
- libxml2-dev (for XML/SOAP)

## Network Configuration

The development environment uses:
- Traefik as reverse proxy (HTTP only setup)
- dnsmasq for local domain resolution
- Apache with mod_xsendfile enabled

### Local Domain

The application is accessible at:
```
http://formr.local
```

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-directory>
```

2. Start the containers:
```bash
docker-compose up -d
```

3. Initialize the database:
```bash
./setup.sh
```

## Container Architecture

The setup consists of multiple containers:
- **formr_app**: Main PHP/Apache application
- **mysql**: Database server
- **opencpu**: R computing environment
- **php_daemon**: Background task processor
- **traefik**: Reverse proxy
- **dnsmasq**: Local DNS resolver

## Known Issues & Solutions

1. If you encounter SSL-related issues:
   - The current setup uses HTTP for local development
   - SSL certificates are not required

2. Database connection issues:
   - Ensure the MySQL container is fully initialized before accessing the application
   - Check the database credentials in the .env file

3. Spreadsheet handling:
   - The PHP intl extension is required for Unicode normalization
   - Ensure file permissions are correct for uploads

## Development Notes

- Container rebuilding: `docker-compose build <service-name>`
- Viewing logs: `docker-compose logs -f <service-name>`
- Accessing containers: `docker-compose exec <service-name> bash`

## Additional Resources

- [Docker Documentation](https://docs.docker.com)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [PHP Extensions Documentation](https://www.php.net/manual/en/extensions.php)
