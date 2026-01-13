# QuestDB Slim (No HTTP)

Minimal QuestDB image with HTTP/Web Console disabled. Only PostgreSQL wire protocol and ILP TCP are enabled.

~280MB vs ~450MB official image (saves ~170MB by removing web console assets and using Alpine JRE).

**Drop-in replacement** for `questdb/questdb` - same ports (8812, 9009), volume paths, and data persistence. Just smaller and without HTTP/Web Console.

## Ports

| Port | Protocol | Description              |
| ---- | -------- | ------------------------ |
| 8812 | TCP      | PostgreSQL wire protocol |
| 9009 | TCP      | InfluxDB Line Protocol   |

HTTP (9000) and metrics (9003) are **disabled** by default.

## Build

```bash
# Single arch
docker build -t ghcr.io/levitree/questdb-slim:latest .

# Multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/levitree/questdb-slim:latest --push .

# Specific version
docker build --build-arg QUESTDB_VERSION=9.2.3 -t ghcr.io/levitree/questdb-slim:9.2.3 .
```

## Usage

```bash
# Basic
docker run -d \
  -p 8812:8812 \
  -p 9009:9009 \
  -v questdb-data:/var/lib/questdb \
  ghcr.io/levitree/questdb-slim:latest

# With PostgreSQL credentials
docker run -d \
  -e QDB_PG_USER=myuser \
  -e QDB_PG_PASSWORD=mypassword \
  -p 8812:8812 \
  -p 9009:9009 \
  -v questdb-data:/var/lib/questdb \
  ghcr.io/levitree/questdb-slim:latest

# Custom JVM settings
docker run -d \
  -e JAVA_OPTS="-Xms1g -Xmx2g" \
  -p 8812:8812 \
  -p 9009:9009 \
  ghcr.io/levitree/questdb-slim:latest
```

## Connecting

**PostgreSQL (psql/pgwire):**

```bash
psql -h localhost -p 8812 -U admin -d qdb
# Default password: quest
```

**InfluxDB Line Protocol:**

```bash
echo "sensors,location=london temperature=22.5 $(date +%s)000000000" | nc localhost 9009
```

## Environment Variables

| Variable          | Default             | Description         |
| ----------------- | ------------------- | ------------------- |
| `QDB_PG_USER`     | `admin`             | PostgreSQL username |
| `QDB_PG_PASSWORD` | `quest`             | PostgreSQL password |
| `JAVA_OPTS`       | `-Xms512m -Xmx512m` | JVM options         |

## Custom Configuration

Mount a custom `server.conf`:

```bash
docker run -d \
  -v ./server.conf:/var/lib/questdb/conf/server.conf:ro \
  -p 8812:8812 \
  ghcr.io/levitree/questdb-slim:latest
```

## Re-enabling HTTP

If you need HTTP/web console, add to your mounted `server.conf`:

```properties
http.enabled=true
http.bind.to=0.0.0.0:9000
```

And expose port 9000.

## What's Disabled

- HTTP REST API (`http.enabled=false`)
- Web Console (assets removed)
- Metrics endpoint (`metrics.enabled=false`)
- UDP line protocol (`line.udp.enabled=false`)
- Telemetry (`telemetry.enabled=false`)
