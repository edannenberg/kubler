#!/bin/bash
set -a

# To override variables defined in run.conf, while stile providing
# POSIX parameter expansion, override before sourcing the wrapper script.

# docker-compose project name, essentially the container name prefix. no white space!
DC_PROJECT_NAME="${DC_PROJECT_NAME:-riemann}"

# source generic wrapper script and defaults from run.conf
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../inc/dc-wrapper.sh" || exit 1

# docker-compose file location
DC_FILE="${DC_DIR}/riemann_influxdb_grafana.yml"

# services config

# riemann
RIEMANN_CONFIG_PATH="${RIEMANN_CONFIG_PATH:-${DC_DIR}/riemann/server/}"
# riemann dashboard
RIEMANN_DASH_CONFIG_PATH="${RIEMANN_DASH_CONFIG_PATH:-${DC_DIR}/riemann/dashboard/}"

# influxdb credentials, changing these will require
INFLUXDB_HOST="${INFLUXDB_HOST:-influxdb}"
INFLUXDB_PORT="${INFLUXDB_PORT:-8086}"
INFLUXDB_DBNAME="${INFLUXDB_DBNAME:-test_metrics}"
INFLUXDB_USER="${INFLUXDB_USER:-root}"
INFLUXDB_PASS="${INFLUXDB_PASS:-root}"
# host path mounted as data folder in influxdb container
INFLUXDB_DATA_PATH="${INFLUXDB_DATA_PATH:-${DC_DATA_ROOT}/${DC_PROJECT_NAME}/influxdb/}"
# grafana
GRAFANA_DATA_PATH="${GRAFANA_DATA_PATH:-${DC_DATA_ROOT}/${DC_PROJECT_NAME}/grafana/}"
# nginx-proxy config
RIEMANN_VHOST_URL="${RIEMANN_VHOST_URL:-riemann.void}"
RIEMANN_PROXY_PORT="${RIEMANN_PROXY_PORT:-4567}"
INFLUXDB_VHOST_URL="${INFLUXDB_VHOST_URL:-influxdb.void}"
INFLUXDB_PROXY_PORT="${INFLUXDB_PROXY_PORT:-8083}"
GRAFANA_VHOST_URL="${GRAFANA_VHOST_URL:-grafana.void}"
GRAFANA_PROXY_PORT="${GRAFANA_PROXY_PORT:-3000}"

STARTUP_MSG=" riemann:\t http://${RIEMANN_VHOST_URL}/ or http://127.0.0.1:4567 \n \
grafana:\t http://${GRAFANA_VHOST_URL}/ or http://127.0.0.1:3000 \n \
\t\t login: admin/admin \n \
influxdb:\t http://${INFLUXDB_VHOST_URL}/ or http://127.0.0.1:8083 \n \
\t\t login: ${INFLUXDB_USER}/${INFLUXDB_PASS} \n\n \
create the test database: \n\n \
curl -G http://localhost:8086/query --data-urlencode 'q=CREATE DATABASE ${INFLUXDB_DBNAME}' \n\n \
configure grafana: \n\n \
curl -X POST -H 'Content-Type: application/json' -d @${DC_DIR}/grafana/datasource.json \
admin:admin@localhost:3000/api/datasources \n\n \
curl -X POST -H 'Content-Type: application/json' -d @${DC_DIR}/grafana/dashboard.json \
admin:admin@localhost:3000/api/dashboards/db \n\n \
generate some events: \n\n \
docker run -it --rm --hostname someapphost --link ${DC_PROJECT_NAME}_riemann_1:riemann \
gentoobb/riemann-dash riemann-health -h riemann"

dc-wrapper "$@"
