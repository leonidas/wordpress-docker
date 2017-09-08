#!/bin/bash
set -xue

cd `dirname "${BASH_SOURCE[0]}"`

curl -o Dockerfile.dist https://raw.githubusercontent.com/docker-library/wordpress/master/php5.6/apache/Dockerfile
curl -o docker-entrypoint.dist.sh https://raw.githubusercontent.com/docker-library/wordpress/master/php5.6/apache/docker-entrypoint.sh

# disable all volumes and inject SSMTP
sed -e 's/^VOLUME/#VOLUME/' -e 's/apt-get install -y /apt-get install -y ssmtp /' Dockerfile.dist > Dockerfile

# do our own setup
cat Dockerfile.footer >> Dockerfile

# copy everything except the final exec line from original docker-entrypoint.sh to ours, and then add our own additions
fgrep -vx 'exec "$@"' docker-entrypoint.dist.sh > docker-entrypoint.sh
cat docker-entrypoint.footer.sh >> docker-entrypoint.sh
