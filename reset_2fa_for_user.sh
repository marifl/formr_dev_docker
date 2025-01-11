source .env
docker exec -it formr_app php bin/reset_2fa.php "$@"