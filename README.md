# formr Development Environment Setup

This guide provides step-by-step instructions for setting up the formr development environment using Docker, even if you're not familiar with technical tools.

> **IMPORTANT**: This setup has only been tested on macOS with Apple Silicon (M4) processors. Compatibility with other systems is not guaranteed.

## Complete Installation Guide for Beginners

### Step 1: Install Homebrew (Package Manager)

Homebrew is a tool that helps you install other software. Open Terminal (press Cmd+Space, type "Terminal", and press Enter), then copy and paste this command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Press Enter and follow the on-screen instructions. You may be asked to enter your password.

After installation, you might need to add Homebrew to your PATH. If prompted, copy and paste the suggested commands.

### Step 2: Install Git (Version Control)

Git is a tool that helps manage code. Install it using Homebrew by typing:

```bash
brew install git
```

Verify the installation by typing:

```bash
git --version
```

You should see the Git version number.

### Step 3: Install Docker Desktop

Docker Desktop allows you to run the formr application in a container:

1. Download Docker Desktop from [Docker Desktop Website](https://www.docker.com/products/docker-desktop/)
2. Double-click the downloaded file and follow the installation wizard
3. After installation, open Docker Desktop from your Applications folder
4. When prompted, ensure Rosetta 2 translation is enabled for Apple Silicon Macs
5. Go to Docker Desktop Preferences > Resources and allocate at least 4GB of RAM

### Step 4: Install mkcert (for HTTPS)

mkcert helps create secure connections for local development:

```bash
brew install mkcert
mkcert -install
```

You may be asked for your password during the installation.

### Step 5: Clone the Repository

1. Create a folder where you want to store the project:
```bash
mkdir -p ~/Projects
cd ~/Projects
```

2. Clone (download) the repository:
```bash
git clone <repository-url>
cd <repository-directory>
```
Replace `<repository-url>` with the actual URL of the repository, and `<repository-directory>` with the name of the directory created by the clone command.

### Step 6: Run the Setup Script

Run the setup wrapper script which will guide you through the rest of the installation:

```bash
./setup_wrapper.sh
```

Follow the interactive prompts in the script. This will:
- Set up environment configuration
- Configure Docker
- Set up CoreDNS for network routing
- Configure HTTPS
- Start the application

> **IMPORTANT**: Always use `setup_wrapper.sh` for installation and configuration. This interactive script handles all necessary setup steps.

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

1. **Homebrew Installation Issues**
   - If you see "command not found" errors after installing Homebrew, you may need to restart your Terminal or add Homebrew to your PATH
   - Follow the instructions shown after Homebrew installation

2. **Docker Installation Issues**
   - Ensure virtualization is enabled in your Mac's security settings
   - For Apple Silicon Macs, ensure Rosetta 2 is installed

3. **Database Connection Issues**
   - Ensure MariaDB container is fully initialized
   - Check credentials in `.env` file
   - Verify network configurations

4. **Spreadsheet Handling**
   - PHP intl extension is required for Unicode normalization
   - Verify file upload permissions

5. **Local Domain Resolution**
   - If formr.local doesn't resolve, add it to your hosts file:
     ```
     127.0.0.1 formr.local
     ```
   - To edit hosts file: `sudo nano /etc/hosts`
   - Add the line above, press Ctrl+O to save, then Ctrl+X to exit

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Create a Pull Request

## Notes

just in case you wondered: All passwords, mail adresses, user names etc. that may be scattered around some files are randomly generated and don't actually exist.

## Additional Resources

- [Docker Documentation](https://docs.docker.com)
- [PHP Documentation](https://www.php.net/docs.php)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [OpenCPU Documentation](https://www.opencpu.org/api.html)
