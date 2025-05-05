FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libicu-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    libxml2-dev \
    libapache2-mod-xsendfile \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli pdo pdo_mysql zip soap intl

# Configure Apache and enable required modules
RUN a2enmod xsendfile rewrite headers ssl && \
    # Need rewrite module for HTTP to HTTPS redirection
    a2enmod rewrite && \
    # Create directory for formr
    mkdir -p /formr && \
    chown -R www-data:www-data /formr && \
    # Configure Apache
    sed -i 's!/var/www/html!/formr!g' /etc/apache2/apache2.conf && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install Xdebug
RUN pecl install xdebug-3.2.2 \
    && docker-php-ext-enable xdebug

# Set working directory
WORKDIR /formr

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

EXPOSE 80 443

CMD ["apache2-foreground"]