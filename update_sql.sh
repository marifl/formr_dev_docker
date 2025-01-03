source .env
docker compose exec -T formr_db sh -c "exec mariadb -uroot -p'${MARIADB_ROOT_PASSWORD}' formr_db" < ./formr_app/formr/sql/patches/040_2fa_support.sql