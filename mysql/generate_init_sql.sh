#!/usr/bin/env bash
#
# generate_init_sql.sh - Dynamically generate init.sql with passwords from .env
#
# This script extracts database credentials from the .env file and generates
# an init.sql file that will be used by MariaDB to initialize the database.

set -e

# Define color functions for better user feedback
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NORMAL="\033[0m"

print_green() { echo -e "${GREEN}$*${NORMAL}"; }
print_red() { echo -e "${RED}$*${NORMAL}"; }
print_yellow() { echo -e "${YELLOW}$*${NORMAL}"; }
print_blue() { echo -e "${BLUE}$*${NORMAL}"; }

# Path to .env file and init.sql
ENV_FILE=".env"
INIT_SQL_DIR="mysql/dbinitial"
INIT_SQL_FILE="${INIT_SQL_DIR}/init.sql"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
  print_red "Error: .env file not found!"
  echo "Please create a .env file with database credentials."
  exit 1
fi

# Extract database credentials from .env
root_password=$(grep -E "^MARIADB_ROOT_PASSWORD=" "$ENV_FILE" | sed -E "s/^MARIADB_ROOT_PASSWORD=//" | tr -d '"')
user_password=$(grep -E "^MARIADB_PASSWORD=" "$ENV_FILE" | sed -E "s/^MARIADB_PASSWORD=//" | tr -d '"')
db_user=$(grep -E "^MARIADB_USER=" "$ENV_FILE" | sed -E "s/^MARIADB_USER=//" | tr -d '"')
db_name=$(grep -E "^MARIADB_DATABASE=" "$ENV_FILE" | sed -E "s/^MARIADB_DATABASE=//" | tr -d '"')

# Default values if not found in .env
db_user=${db_user:-formr_user}
db_name=${db_name:-formr_db}

# Extract FormR admin credentials from .env
formr_email=$(grep -E "^FORMR_EMAIL=" "$ENV_FILE" | sed -E "s/^FORMR_EMAIL=//" | tr -d '"')
formr_password=$(grep -E "^FORMR_PASSWORD=" "$ENV_FILE" | sed -E "s/^FORMR_PASSWORD=//" | tr -d '"')

# Check if passwords were found
if [ -z "$root_password" ]; then
  print_red "Error: MARIADB_ROOT_PASSWORD not found in .env!"
  exit 1
fi

if [ -z "$user_password" ]; then
  print_red "Error: MARIADB_PASSWORD not found in .env!"
  exit 1
fi

if [ -z "$formr_email" ]; then
  print_red "Error: FORMR_EMAIL not found in .env!"
  exit 1
fi

if [ -z "$formr_password" ]; then
  print_red "Error: FORMR_PASSWORD not found in .env!"
  exit 1
fi

# Generate bcrypt hash for the FormR admin password
formr_password_hash=$(php -r "echo password_hash('$formr_password', PASSWORD_BCRYPT);")

print_blue "Generating init.sql with credentials from .env..."

# Create init.sql directory if it doesn't exist
mkdir -p "$INIT_SQL_DIR"

# Generate init.sql file
cat > "$INIT_SQL_FILE" << EOF
CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS formr_migrations CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges to database user with password from .env
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%' IDENTIFIED BY '$user_password';
GRANT ALL PRIVILEGES ON formr_migrations.* TO '$db_user'@'%' IDENTIFIED BY '$user_password';

-- Allow root to connect from anywhere with password from .env
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$root_password' WITH GRANT OPTION;

-- Create default admin user with credentials from .env
INSERT IGNORE INTO \`survey_users\` (\`email\`, \`password\`, \`admin\`, \`email_verified\`, \`created\`, \`modified\`)
VALUES ('$formr_email', '$formr_password_hash', 1, 1, NOW(), NOW());

FLUSH PRIVILEGES;
EOF

print_green "Successfully generated $INIT_SQL_FILE with database credentials from .env!"
print_green "Root password: [hidden for security]"
print_green "User password: [hidden for security]"
print_yellow "Note: This file will be used to initialize the database when the container starts."
print_yellow "      Run this script whenever you change passwords in .env!"

