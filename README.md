# formr Development Environment Setup (Docker)

This guide provides instructions for setting up the formr development environment using Docker.

## Prerequisites

Before you begin, you need to install several dependencies. Follow the step-by-step instructions below for your operating system.

### Required Dependencies

- **Homebrew** (macOS only): Package manager for macOS
- **Docker Desktop**: Container platform
- **Git**: Version control system
- **mkcert**: Tool for creating locally-trusted development certificates
- **curl**: Command-line tool for transferring data
- **bash**: Unix shell (pre-installed on macOS and most Linux distributions)

### Step-by-Step Installation Instructions

#### macOS

1. **Install Homebrew** (Package Manager):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   After installation, follow the instructions to add Homebrew to your PATH.

2. **Install Docker Desktop**:
   ```bash
   brew install --cask docker
   ```
   Alternatively, download from [Docker Desktop Website](https://www.docker.com/products/docker-desktop/) and follow the installation wizard.
   
   After installation:
   - Launch Docker Desktop
   - Go to Preferences > Resources and allocate at least 4GB of RAM
   - If using Apple Silicon (M1/M2), ensure Rosetta 2 translation is enabled

3. **Install Git**:
   ```bash
   brew install git
   ```

4. **Install mkcert** (for HTTPS development):
   ```bash
   brew install mkcert
   mkcert -install
   ```

5. **Install curl** (if not already installed):
   ```bash
   brew install curl
   ```

#### Linux (Ubuntu/Debian)

1. **Update package lists**:
   ```bash
   sudo apt update
   sudo apt upgrade
   ```

2. **Install Docker**:
   ```bash
   # Install dependencies
   sudo apt install apt-transport-https ca-certificates curl software-properties-common

   # Add Docker's official GPG key
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

   # Add Docker repository
   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

   # Install Docker
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io

   # Add your user to the docker group to run Docker without sudo
   sudo usermod -aG docker $USER
   ```
   Log out and log back in for the group changes to take effect.

3. **Install Docker Compose**:
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

4. **Install Git**:
   ```bash
   sudo apt install git
   ```

5. **Install mkcert**:
   ```bash
   # Install dependencies
   sudo apt install libnss3-tools

   # Download and install mkcert
   curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
   chmod +x mkcert-v*-linux-amd64
   sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert

   # Install local CA
   mkcert -install
   ```

#### Windows

1. **Install Docker Desktop**:
   - Download from [Docker Desktop Website](https://www.docker.com/products/docker-desktop/)
   - Run the installer and follow the instructions
   - Ensure WSL 2 is enabled when prompted
   - After installation, start Docker Desktop

2. **Install Git**:
   - Download from [Git for Windows](https://gitforwindows.org/)
   - During installation, select "Use Git from the Windows Command Prompt"
   - Select "Checkout as-is, commit as-is" for line ending conversions

3. **Install mkcert**:
   - Install [Chocolatey](https://chocolatey.org/install) package manager
   - Open PowerShell as Administrator and run:
     ```powershell
     choco install mkcert
     mkcert -install
     ```

4. **Install Windows Terminal** (recommended):
   - Install from the [Microsoft Store](https://aka.ms/terminal)

## System Requirements

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

## Environment Configuration

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Copy environment configuration**:
   ```bash
   cp .env.example .env
   ```
   - Edit `.env` file to customize database credentials, secret keys, and other settings

3. **Run the setup wrapper script**:
   ```bash
   # On macOS/Linux
   ./setup_wrapper.sh

   # On Windows (using Git Bash)
   bash setup_wrapper.sh
   ```

> **IMPORTANT**: Always use `setup_wrapper.sh` for installation and configuration. This script provides an interactive setup process that handles all necessary configuration steps, including environment setup, Docker configuration, CoreDNS setup, and HTTPS configuration.

## Network Configuration

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

## Project Overview

formr is a PHP-based survey framework that allows researchers to create complex multi-stage studies with longitudinal and contingent designs.

### Key Components
- **Web Application**: PHP 8.2 with Apache
- **Database**: MariaDB 11.7
- **R Integration**: OpenCPU
- **Queue System**: PHP daemons for email and session processing

## Development Workflow

### Running the Application
- Start/update environment: `./setup_wrapper.sh`
- Stop containers: `docker-compose down`
- Rebuild specific service: `docker-compose build <service-name>`

### Accessing Containers
```bash
# Access a specific container
docker-compose exec <service-name> bash
```

### Viewing Logs
```bash
# View logs for a specific service
docker-compose logs -f <service-name>
```

## Troubleshooting

1. **Docker Installation Issues**:
   - Ensure virtualization is enabled in BIOS (for Windows/Linux)
   - For Windows, ensure WSL 2 is properly installed and configured
   - For macOS with Apple Silicon, ensure Rosetta 2 is installed

2. **Database Connection Issues**:
   - Ensure MariaDB container is fully initialized
   - Check credentials in `.env` file
   - Verify network configurations

3. **Spreadsheet Handling**:
   - PHP intl extension is required for Unicode normalization
   - Verify file upload permissions

4. **Local Domain Resolution**:
   - If formr.local doesn't resolve, add it to your hosts file:
     ```
     127.0.0.1 formr.local
     ```

## SSL/HTTPS Setup

For local SSL/HTTPS development, use the setup_wrapper.sh script which will guide you through the HTTPS setup process. The script will:

1. Install and configure mkcert if needed
2. Generate appropriate certificates
3. Configure the system to use the certificates
4. Set up proper redirects

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