#!/bin/bash
err(){
    echo "E: $*" >>/dev/stderr
}

find_replace_in_file() {
    filename=$1
    search=$2
    replace=$3
    matching_line=$(grep -n -m 1 -h -E $search $filename | cut -d: -f1)
    echo $matching_line
    # If the matching line exists, replace it with the new line
    if [ ! -z "$matching_line" ]; then
        # Use a backup extension, e.g., .bak
        sudo sed -i.bak "${matching_line}s#.*#$replace#" $filename
        # Remove the backup file
        sudo rm "${filename}.bak"
    fi
}

if [[ ! -f ".env" || ! -f "docker-compose.yml" ]]; then
    err ".env file or docker-compose.yml file not found"
    exit 1
fi

source .env

# Docker compose up formr_app
if [[ $(sudo docker inspect -f '{{.State.Running}}' formr_app) == "true" ]]; then
  echo "formr_app already running ... \n"
else
  echo "Starting formr_app ....\n"
  sudo docker compose up -d formr_app
fi

# Replace domain name in sample apache config with actual domain name and restart container
echo "Waiting for project formr to be ready / downloaded "
while [[ ! -f "./formr_app/formr/config/settings.php"  ]]
do
sleep 2
done

#copy schema.sql from repository
rm -Rf mysql/dbinitial/*
while [[ ! -f "./formr_app/formr/sql/schema.sql"  ]]
do
sleep 2
done
cp -f formr_app/formr/sql/schema.sql mysql/dbinitial/

echo "Configure domain name (see .env FORMR_DOMAIN) in apache config"
find_replace_in_file "./formr_app/apache/sites-enabled/formr.conf" "Define\s+FORMR_DOMAIN" "Define FORMR_DOMAIN ${FORMR_DOMAIN}"
#find_replace_in_file "./etc/formr/apache.subdomain.conf" "Define\s+FORMR_DOMAIN" "Define FORMR_DOMAIN ${FORMR_DOMAIN}"

echo "Enter values in formr configuration"
formr_config="./formr_app/formr/config/settings.php"
find_replace_in_file $formr_config "'host'\s*=>\s*'localhost'" "\t'host' => 'formr_db',"
find_replace_in_file $formr_config "'login'\s*=>\s*'user'" "\t'login' => '${MARIADB_USER}',"
find_replace_in_file $formr_config "'password'\s*=>\s*'password'" "\t'password' => '${MARIADB_PASSWORD}',"
find_replace_in_file $formr_config "'database'\s*=>\s*'database'" "\t'database' => '${MARIADB_DATABASE}',"
find_replace_in_file $formr_config "'encoding'\s*=>\s*" "\t'encoding' => 'utf8mb4',"

find_replace_in_file $formr_config "'domain'\s=>\s'.formr.org'" "\t'domain' => '${FORMR_DOMAIN}',"
find_replace_in_file $formr_config "'public_url'\s=>\s'https://public.opencpu.org'" "\t'public_url' => 'http://${OPENCPU_DOMAIN}',"

find_replace_in_file $formr_config "'protocol' =>" "'protocol' => 'http://',"
find_replace_in_file $formr_config "use_study_subdomains" "\$settings['use_study_subdomains'] = false;"
find_replace_in_file $formr_config "doc_root" "		'doc_root' => 'localhost/',"
find_replace_in_file $formr_config "study_domain" "		'study_domain' => 'localhost/',"



if [ -f "mysql/dbinitial/schema.sql" ]
then
    
    find_replace_in_file "mysql/dbinitial/schema.sql" "NOT\sEXISTS\sformr" "CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE} CHARSET=utf8mb4 COLLATE utf8mb4_unicode_ci;"
    find_replace_in_file "mysql/dbinitial/schema.sql" "USE\sformr" "USE ${MARIADB_DATABASE};"
    sudo docker compose up -d formr_db
    while [[ $(sudo docker inspect -f '{{.State.Running}}' formr_db) != "true" ]]
    do
    echo "Waiting for formr_db to start running "
    sleep 2
    done
    sudo docker exec -i formr_db sh -c "exec mariadb -uroot -p${MARIADB_ROOT_PASSWORD}" < mysql/dbinitial/schema.sql
fi

sudo docker compose up -d formr_db  
sudo docker compose restart formr_app

# Create opencpu config files
# sudo mkdir -p etc/opencpu
# sudo touch etc/opencpu/Rprofile
# sudo touch etc/opencpu/Renviron

sudo docker compose up -d

# create superadmin
docker exec -it formr_app php bin/add_user.php -e ${FORMR_EMAIL} -p $FORMR_PASSWORD -l "100"

echo "============================================================"
echo "|                                                          |"
echo "| TODO:                                                    |"
echo "| 1. Configure formr in formr/config/settings.php          |"
echo "| 2. Test and report any problems                          |"
echo "|                                                          |"
echo "============================================================"
