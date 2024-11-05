FROM alpine:latest AS tunnel

RUN apk add --no-cache curl jq

# Get latest release from GitHub, download the files and save them with new names
RUN RELEASE_URL=$(curl -s https://api.github.com/repos/heiher/hev-socks5-tunnel/releases/latest | jq -r '.assets[] | select(.name == "hev-socks5-tunnel-linux-arm32" or .name == "hev-socks5-tunnel-linux-arm64" or .name == "hev-socks5-tunnel-linux-x86_64") | .browser_download_url') && \
    curl -L $(echo "$RELEASE_URL" | grep -o 'https://[^ ]*hev-socks5-tunnel-linux-arm32') -o /tmp/hev-socks5-tunnel-linux-arm && \
    curl -L $(echo "$RELEASE_URL" | grep -o 'https://[^ ]*hev-socks5-tunnel-linux-arm64') -o /tmp/hev-socks5-tunnel-linux-arm64 && \
    curl -L $(echo "$RELEASE_URL" | grep -o 'https://[^ ]*hev-socks5-tunnel-linux-x86_64') -o /tmp/hev-socks5-tunnel-linux-amd64

    
FROM alpine:latest AS byedpi

RUN apk add --no-cache curl jq tar

# Get latest release from GitHub, download the files and save them with new names
RUN RELEASE_URLS=$(curl -s https://api.github.com/repos/hufrea/byedpi/releases/latest | jq -r '.assets[] | select(.name | test("byedpi-.*-armv7l.tar.gz") or test("byedpi-.*-aarch64.tar.gz") or test("byedpi-.*-x86_64.tar.gz")) | .browser_download_url') && \
    curl -L $(echo "$RELEASE_URLS" | grep -o 'https://[^ ]*byedpi-.*-armv7l.tar.gz') -o /tmp/byedpi-armv7l.tar.gz && \
    curl -L $(echo "$RELEASE_URLS" | grep -o 'https://[^ ]*byedpi-.*-aarch64.tar.gz') -o /tmp/byedpi-aarch64.tar.gz && \
    curl -L $(echo "$RELEASE_URLS" | grep -o 'https://[^ ]*byedpi-.*-x86_64.tar.gz') -o /tmp/byedpi-x86_64.tar.gz

WORKDIR /tmp

RUN for archive in *.tar.gz; do tar -xzvf "$archive" -C .; done && \
    mv ciadpi-armv7l ciadpi-arm && \
    mv ciadpi-aarch64 ciadpi-arm64 && \
    mv ciadpi-x86_64 ciadpi-amd64

    
FROM alpine:latest

RUN apk update && apk add --no-cache iproute2

ARG TARGETARCH
COPY --chmod=755 entrypoint.sh /
COPY --from=tunnel --chmod=755 /tmp/hev-socks5-tunnel-linux-${TARGETARCH} /usr/bin/hev-socks5-tunnel
COPY --from=byedpi --chmod=755 /tmp/ciadpi-${TARGETARCH} /opt/byedpi/ciadpi

# Create user with UID 1000
RUN adduser -u 1000 -D -s /bin/sh ciadpi

ENTRYPOINT ["/entrypoint.sh"]