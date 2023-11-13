FROM php:8.2.2-cli
# syntax=docker/dockerfile:1
# Install System & PHP Dependencies
RUN apt-get update 
RUN apt-get upgrade -y
RUN apt-get install -y pandoc libzip-dev libxml2-dev libpng-dev libonig-dev libsodium-dev libcurl4-openssl-dev git cron
RUN docker-php-ext-install zip xml gd intl mbstring curl pdo pdo_mysql 
RUN docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl


WORKDIR /formr
