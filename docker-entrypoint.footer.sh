set -xue

# These lines will be appended from docker-entrypoint.footer.sh to docker-entrypoint.dist.sh to produce a working docker-entrypoint.sh
# If you change docker-entrypoint.footer.sh, remember to re-run wordpress/update-dockerfile.sh.
# Do not edit the resulting docker-entrypoint.sh manually. Changes will be lost.

# Copy Git managed files
# Commented out because we have none :)
# cp -R /usr/src/wp-content/* /var/www/html/wp-content

# On first run, populate wp-content/uploads
# [[ ! -d /var/www/html/wp-content/uploads/2017 ]] && tar -C /var/www/html -xzf /usr/src/wp-content.tar.gz

# Fix permissions
chown -R root:www-data wp-content

WORDPRESS_MAINTENANCE_MODE=${WORDPRESS_MAINTENANCE_MODE:-false}

if [[ "$WORDPRESS_MAINTENANCE_MODE" == "true" ]]; then
    echo "NOTE: Running in maintenance mode. Plugin directory is server-writable."
    find . -type d -exec chmod 2775 \{\} +
    find . -type f -exec chmod 664 \{\} +
else
    echo "Maintenance mode disabled. Everything except upload directory is read-only."
    find . -type d -exec chmod 1755 \{\} +
    find . -type f -exec chmod 644 \{\} +
    find wp-content/uploads -type d -exec chmod 2775 \{\} +
    find wp-content/uploads -type f -exec chmod 664 \{\} +
fi

# generate ssmtp.conf
cat > /etc/ssmtp/ssmtp.conf << EOF
mailhub=${WORDPRESS_SMTP_SERVER:-email-smtp.eu-west-1.amazonaws.com}:465

Hostname=${WORDPRESS_PUBLIC_HOSTNAME:-leonidasoy.fi}
AuthUser=${WORDPRESS_SMTP_USERNAME:-NOTSET}
AuthPass=${WORDPRESS_SMTP_PASSWORD:-NOTSET}

FromLineOverride=yes
UseTLS=yes
EOF

cat > /etc/ssmtp/revaliases << EOF
root:${WORDPRESS_ROOT_MAIL_TO:-it@leonidasoy.fi}:${WORDPRESS_SMTP_SERVER:-email-smtp.eu-west-1.amazonaws.com:465}
EOF

# our script removes this line from the end of docker-entrypoint.dist.sh, so re-add it
exec "$@"
