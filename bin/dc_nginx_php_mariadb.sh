#!/bin/bash
set -a

# To override variables defined in run.conf, while stile providing
# POSIX parameter expansion, override before sourcing the wrapper script.

# docker-compose project name, essentially the container name prefix. no white space!
DC_PROJECT_NAME="${DC_PROJECT_NAME:-lamp}"

# source generic wrapper script and defaults from run.conf
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../inc/dc-wrapper.sh" || exit 1

# docker-compose file location
DC_FILE="${DC_DIR}/nginx_php_mariadb.yml"

# services config

# host path mounted as htdocs folder in nginx
HTDOCS_PATH="${HTDOCS_PATH:-${DC_DATA_ROOT}/${DC_PROJECT_NAME}/htdocs/}"
# host path mounted as mysql data folder
SQLDATA_PATH="${SQLDATA_PATH:-${DC_DATA_ROOT}/${DC_PROJECT_NAME}/mysql-data/}"
# main site url
BASE_URL="${BASE_URL:-mysite.void}"
# micro site urls
ADMINER_URL="${ADMINER_URL:-db.${BASE_URL}}"
PHPINFO_URL="${PHPINFO_URL:-phpinfo.${BASE_URL}}"
# all urls we want reverse proxied
VHOST_URL="${VHOST_URL:-${BASE_URL},${ADMINER_URL},${PHPINFO_URL}}"
# misc
XDEBUG="${XDEBUG:-yes}"
XDEBUG_LOCAL_PORT="${XDEBUG_LOCAL_PORT:-9003}"
NGINX_UID="${NGINX_UID:-$(id -u $(whoami))}"
NGINX_GID="${NGINX_GID:-$(id -g $(whoami))}"
# db credentials
MYSQL_ROOT_PW="${MYSQL_ROOT_PW:-root}"
MYSQL_ADMIN_USER="${MYSQL_ADMIN_USER:-admin}"
MYSQL_ADMIN_PW="${MYSQL_ADMIN_PW:-test}"

STARTUP_MSG=" vhost:\t\t http://$BASE_URL/ \n \
adminer:\t http://$ADMINER_URL/adminer.php?server=db&username=${MYSQL_ADMIN_USER} \n \
mariadb:\t login: ${MYSQL_ADMIN_USER}/${MYSQL_ADMIN_PW} \n \
phpinfo:\t http://$PHPINFO_URL/ \n "

if [[ "$XDEBUG" == 'yes' ]]; then
    STARTUP_MSG+="xdebug:\t enabled, mapped to localhost port: ${XDEBUG_LOCAL_PORT}"
else
    STARTUP_MSG+="xdebug:\t\t disabled"
fi

if [ ! -f "${HTDOCS_PATH}/index.php" ]; then
    mkdir -p "${HTDOCS_PATH}"
    echo "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head><h2><?php print 'here be dragons'; ?></h2>" > "${HTDOCS_PATH}/index.php"
fi

dc-wrapper "$@"
