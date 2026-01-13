#!/bin/sh
set -e

QDB_ROOT="${QDB_ROOT:-/var/lib/questdb}"
CONF_DIR="${QDB_ROOT}/conf"
CONF_FILE="${CONF_DIR}/server.conf"

# Create config directory if needed
mkdir -p "${CONF_DIR}"

# Generate minimal server.conf if it doesn't exist
if [ ! -f "${CONF_FILE}" ]; then
    cat > "${CONF_FILE}" << 'EOF'
# HTTP disabled - no web console or REST API
http.enabled=false

# PostgreSQL wire protocol (port 8812)
pg.enabled=true
pg.net.bind.to=0.0.0.0:8812

# InfluxDB Line Protocol over TCP (port 9009)
line.tcp.enabled=true
line.tcp.net.bind.to=0.0.0.0:9009

# Disable UDP (deprecated)
line.udp.enabled=false

# Disable metrics endpoint
metrics.enabled=false

# Telemetry
telemetry.enabled=false

# Cairo engine for SQL (enabled by default, ensures data persistence)
cairo.sql.copy.root=${QDB_ROOT}/tmp

# WAL (Write-Ahead Log) for data durability
wal.enabled.default=true
EOF

    # Apply environment variable overrides only on first run
    [ -n "${QDB_PG_USER}" ] && echo "pg.user=${QDB_PG_USER}" >> "${CONF_FILE}"
    [ -n "${QDB_PG_PASSWORD}" ] && echo "pg.password=${QDB_PG_PASSWORD}" >> "${CONF_FILE}"
fi

# Allow custom JVM options
JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx512m}"

# Set LD_LIBRARY_PATH to help native library loading on Alpine
export LD_LIBRARY_PATH="${JAVA_HOME}/lib:${LD_LIBRARY_PATH}"

exec java ${JAVA_OPTS} \
    -p "/app/questdb.jar" \
    -m io.questdb/io.questdb.ServerMain \
    -d "${QDB_ROOT}" \
    "$@"