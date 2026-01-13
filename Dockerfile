# Stage 1: Download QuestDB and build minimal JRE
FROM eclipse-temurin:21-jdk-alpine AS builder

ARG QUESTDB_VERSION=9.2.3

WORKDIR /build

# Download QuestDB
RUN wget -q "https://github.com/questdb/questdb/releases/download/${QUESTDB_VERSION}/questdb-${QUESTDB_VERSION}-no-jre-bin.tar.gz" \
    && tar -xzf questdb-${QUESTDB_VERSION}-no-jre-bin.tar.gz --strip-components=1 \
    && rm questdb-${QUESTDB_VERSION}-no-jre-bin.tar.gz \
    && rm -f public.zip

# Find required modules and build minimal JRE
RUN apk add --no-cache binutils \
    && MODULES=$(jdeps --ignore-missing-deps --print-module-deps --multi-release 21 questdb.jar 2>/dev/null || echo "java.base,java.logging,java.sql,java.naming,java.management,java.instrument,jdk.unsupported,jdk.crypto.ec,java.desktop") \
    && echo "Detected modules: $MODULES" \
    && jlink \
        --add-modules ${MODULES},jdk.crypto.ec,java.desktop \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=zip-6 \
        --output /jre

# Stage 2: Final minimal image
FROM alpine:3.21

ENV JAVA_HOME=/opt/java \
    PATH="/opt/java/bin:$PATH" \
    QDB_ROOT=/var/lib/questdb

# Copy custom JRE
COPY --from=builder /jre $JAVA_HOME

# Copy QuestDB
COPY --from=builder /build/questdb.jar /app/questdb.jar

# Create user and directories
RUN addgroup -g 10001 -S questdb \
    && adduser -u 10001 -S -D -G questdb -H -h ${QDB_ROOT} -s /sbin/nologin questdb \
    && mkdir -p ${QDB_ROOT} \
    && chown -R questdb:questdb ${QDB_ROOT}

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER questdb
WORKDIR ${QDB_ROOT}

# PostgreSQL wire protocol + ILP TCP
EXPOSE 8812 9009

ENTRYPOINT ["/docker-entrypoint.sh"]