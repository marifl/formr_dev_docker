#!/bin/bash

# echo get current version
VERSION_FILE="/formr/formr.${FORMR_TAG//\//_}.version" # replace slashes (as in feature branches with _)

if [ ! -f "${VERSION_FILE}" ]
then
    git clone -b ${FORMR_TAG} https://github.com/rubenarslan/formr.org.git /formr
    echo "Cloned formr branch ${FORMR_TAG} into /formr"

    if [ ! -d "/formr/config" ]
    then
        cp -r /formr/config-dist /formr/config
    fi
    echo "Created configuration"

    chown -R www-data:www-data /formr/tmp

    composer install

    echo "Formr Version: ${FORMR_TAG}" > ${VERSION_FILE}
fi

# ln -sf /proc/self/fd/1 /formr/tmp/logs/errors.log
ln -sf /proc/self/fd/1 /var/log/apache2/access.log
ln -sf /proc/self/fd/1 /var/log/apache2/error.log

# if [ ! -f "/etc/formr/apache.conf" ]
# then
#     cp -r /config-examples/. /etc/formr/
# fi

# if [ ! -f "/etc/apache2/sites-available/formr.conf" ]
# then
#     ln -s /etc/formr/${FORMR_APACHE_CONFIG} /etc/apache2/sites-available/formr.conf
# fi

# a2dissite 000-default
# a2ensite formr
# a2enmod rewrite headers ssl xsendfile proxy proxy_http proxy_balancer lbmethod_byrequests

/usr/sbin/apache2ctl stop

/usr/sbin/apache2ctl -D FOREGROUND

