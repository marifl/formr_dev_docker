FROM php:8.2.2-apache

# Install System & PHP Dependencies
RUN apt-get update 
RUN apt-get upgrade -y
RUN apt-get install -y pandoc libzip-dev libxml2-dev libpng-dev libonig-dev libsodium-dev libcurl4-openssl-dev git unzip
RUN apt-get install -y libapache2-mod-xsendfile
RUN docker-php-ext-install zip xml gd intl mbstring curl pdo pdo_mysql
RUN docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /formr

RUN a2enmod rewrite headers ssl xsendfile proxy proxy_http proxy_balancer lbmethod_byrequests

EXPOSE 80

#COPY config-examples /config-examples

COPY docker-entrypoint.sh /docker-entrypoint.sh

# Remove this when apache config is added to repository
# COPY apache.conf /apache.conf


ENTRYPOINT [ "/docker-entrypoint.sh" ]

