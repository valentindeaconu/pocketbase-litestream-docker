# syntax=docker/dockerfile:1

FROM alpine:3.21

# Install the dependencies
RUN apk add --no-cache \
    ca-certificates \
    unzip \
    wget \
    zip \
    zlib-dev \
    bash

ARG TARGETOS
ARG TARGETARCH

# Download and install Litestream
# renovate: datasource=github-releases depName=benbjohnson/litestream
ARG LITESTREAM_VERSION=0.3.13
ADD https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz \
    && chmod +x /usr/local/bin/litestream \
    && rm -f /tmp/litestream.tar.gz

# Download and install PocketBase
# renovate: datasource=github-releases depName=pocketbase/pocketbase
ARG POCKETBASE_VERSION=0.25.4
ADD https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_${TARGETOS}_${TARGETARCH}.zip /tmp/pocketbase.zip
RUN unzip /tmp/pocketbase.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/pocketbase \
    && rm -f /tmp/pocketbase.zip

# Copy Litestream configuration file
COPY etc/litestream.yml /etc/litestream.yml

# Copy custom entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

CMD [ "entrypoint.sh" ]
