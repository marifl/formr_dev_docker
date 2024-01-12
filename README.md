# formr dockerized development environment

This is just an attempt to make it easier to start developing formr. This setup is not suitable for production. It permits arbitrary code execution on OpenCPU, the database is not encrypted, the HTTP connection is not encrypted, etc.

### 0. Requirements
- [Docker & Docker compose](https://docs.docker.com/compose/install) (docker compose minimum version is 2)

## Short version
- Clone this repository
- Run `./setup.sh` (careful, this is destructive)
- Configure values in `.env` (not needed for a quick try)
- Run `./build.sh`
- Configure `formr_app/formr/config/settings.php`, especially the email account used for email verification. Run `docker compose restart` after file changed.

## Long Version

### 1. Copy and prepare files
- Run `./setup.sh`
- This will generate some random passwords for you automatically.

### 2. Configure Database and Domain names
- Open `.env` and fill in the correct configuration items
- `.env` config item :
````
MARIADB_ROOT_PASSWORD -> Mysql password of root, by default "generate-password"
MARIADB_DATABASE			-> Mysql database name, default = formr_db
MARIADB_USER				  -> Mysql database user, default = formr_user
MARIADB_PASSWORD 			-> Mysql database password of user MARIADB_USER, by default "generate-password"

MAIN_DOMAIN           -> The main domain of your formr instance.
FORMR_DOMAIN			    -> Domain of formr_app. Can fill with multiple domain with separated by comma (,). Default value = localhost
OPENCPU_DOMAIN			  -> (Sub)domain for opencpu. Default value = localhost:8080

FORMR_EMAIL			      -> Email for the first superadmin
FORMR_PASSWORD        -> Default superadmin password, by default "generate-password"

FORMR_TAG			        -> formr version or branch. Please check on this link https://github.com/rubenarslan/formr.org/tags. Default value = feature/dockerprep

TIMEZONE              -> defaults to Europe/Berlin

````

### 3. Build containers and Install initial schema
- Run `./build.sh`
- This process will be create a mysql database, pull formr project from github, create and run the containers for OpenCPU, formr and its daemons:
  - formr_app  = container of formr application
  - formr_db   = container of mysql db
  - opencpu    = container of opencpu
  - formrsessionqueue = daemon that takes care of participants moving along in the run
  - formrmailqueue = daemon that takes care of email sending

### 4. File configuration
Open `formr_app/formr/config/settings.php`. Configure as needed, especially the email account used for email verification.