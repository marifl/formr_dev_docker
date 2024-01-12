#!/bin/bash

echo "Overwrite .env file"
cp .env.example .env
echo "Stop and destroy any containers"
sudo docker compose down

# 
echo "===================================================================="
echo "|                                                                   |"
echo "| 1. Configure entries in .env file                                 |"
echo "| 2. Run ./build.sh                                                 |"
echo "|                                                                   |"
echo "===================================================================="
