#!/bin/bash

echo "Stop and destroy any containers"
if [ $( sudo docker ps -a | wc -l ) -gt 0 ]; then
    sudo docker compose down
fi

cp .env.example .env

# 
echo "===================================================================="
echo "|                                                                   |"
echo "| 1. Configure entries in .env file                                 |"
echo "| 2. Run ./build.sh                                                 |"
echo "|                                                                   |"
echo "===================================================================="
