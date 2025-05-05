# formr Development Environment Setup

This guide provides instructions for setting up the formr development environment using Docker.

> **IMPORTANT**: This setup has only been tested on macOS with Apple Silicon (M4) processors. Compatibility with other systems is not guaranteed.

## Prerequisites

- **Docker Desktop**: Version 4.15.0 or later
  - Download from [Docker Desktop Website](https://www.docker.com/products/docker-desktop/)
  - Ensure Rosetta 2 translation is enabled for Apple Silicon Macs

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-directory>
```

2. Run the setup wrapper script:
```bash
./setup_wrapper.sh
```

> **IMPORTANT**: Always use `setup_wrapper.sh` for installation and configuration. This interactive script handles all necessary setup steps including environment configuration, Docker setup, CoreDNS configuration, and HTTPS setup.

## Project Overview

formr is a PHP-based survey framework that allows researchers to create complex multi-stage studies with longitudinal and contingent designs.

### Key Components
- **Web Application**: PHP 8.2 with Apache
- **Database**: MariaDB 11.7
- **R Integration**: OpenCPU
- **Queue System**: PHP daemons for email and session processing

## System Architecture

The development environment uses:
- Apache with mod_xsendfile enabled
- MariaDB for database
- OpenCPU for R integration
- PHP daemons for email and session queues

### Local Domain

The application is accessible at:
```
http://formr.local
```

## Development Workflow

### Running the Application
- Start/update environment: `./setup_wrapper.sh`
- Stop containers: `docker compose down`
- Rebuild specific service: `docker compose build <service-name>`

### Accessing Containers
```bash
# Access a specific container
docker compose exec <service-name> bash
```

### Viewing Logs
```bash
# View logs for a specific service
docker compose logs -f <service-name>
```

## Troubleshooting

1. **Database Connection Issues**
   - Ensure MariaDB container is fully initialized
   - Check credentials in `.env` file
   - Verify network configurations

2. **Spreadsheet Handling**
   - PHP intl extension is required for Unicode normalization
   - Verify file upload permissions

3. **Local Domain Resolution**
   - If formr.local doesn't resolve, add it to your hosts file:
     ```
     127.0.0.1 formr.local
     ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Create a Pull Request

## License

[Specify your project's license here]

## Additional Resources

- [Docker Documentation](https://docs.docker.com)
- [PHP Documentation](https://www.php.net/docs.php)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [OpenCPU Documentation](https://www.opencpu.org/api.html)