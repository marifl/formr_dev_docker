source .env
docker compose exec -it formr_db sh -c "exec mariadb -uroot -p'${MARIADB_ROOT_PASSWORD}' formr_db"