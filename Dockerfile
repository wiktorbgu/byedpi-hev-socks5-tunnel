FROM alpine:latest AS build

RUN apk add --no-cache curl jq
ARG TARGETARCH
WORKDIR /tmp

# Get latest release from GitHub, download the files and save them with new names
RUN RELEASE_URL=$(curl -s https://api.github.com/repos/heiher/hev-socks5-tunnel/releases/latest | jq -r '.assets[] | select(.name == "hev-socks5-tunnel-linux-arm32" or .name == "hev-socks5-tunnel-linux-arm64" or .name == "hev-socks5-tunnel-linux-x86_64") | .browser_download_url') && \
    curl -L $(echo "$RELEASE_URL" | grep -o 'https://[^ ]*hev-socks5-tunnel-linux-arm32') -o hev-socks5-tunnel-linux-arm && \
    curl -L $(echo "$RELEASE_URL" | grep -o 'https://[^ ]*hev-socks5-tunnel-linux-arm64') -o hev-socks5-tunnel-linux-arm64 && \
    curl -L $(echo "$RELEASE_URL" | grep -o 'https://[^ ]*hev-socks5-tunnel-linux-x86_64') -o hev-socks5-tunnel-linux-amd64

# Get latest release from GitHub, download the files and save them with new names
RUN RELEASE_URLS=$(curl -s https://api.github.com/repos/hufrea/byedpi/releases/latest | jq -r '.assets[] | select(.name | test("byedpi-.*-armv7l.tar.gz") or test("byedpi-.*-aarch64.tar.gz") or test("byedpi-.*-x86_64.tar.gz")) | .browser_download_url') && \
    curl -L $(echo "$RELEASE_URLS" | grep -o 'https://[^ ]*byedpi-.*-armv7l.tar.gz') -o byedpi-armv7l.tar.gz && \
    curl -L $(echo "$RELEASE_URLS" | grep -o 'https://[^ ]*byedpi-.*-aarch64.tar.gz') -o byedpi-aarch64.tar.gz && \
    curl -L $(echo "$RELEASE_URLS" | grep -o 'https://[^ ]*byedpi-.*-x86_64.tar.gz') -o byedpi-x86_64.tar.gz

RUN for archive in *.tar.gz; do tar -xzvf "$archive" -C .; done && \
    mv ciadpi-armv7l ciadpi-arm && \
    mv ciadpi-aarch64 ciadpi-arm64 && \
    mv ciadpi-x86_64 ciadpi-amd64 && \
    chmod -R 777 .

#make work structure
RUN mkdir -p build/usr/bin && \
    mv ciadpi-${TARGETARCH} build/usr/bin/ciadpi && \
    mv hev-socks5-tunnel-linux-${TARGETARCH} build/usr/bin/hev-socks5-tunnel
    
COPY --chmod=755 entrypoint.sh build/

FROM alpine:latest

COPY --from=build /tmp/build /

RUN apk update && apk add --no-cache iproute2 && \
    # Create user with UID 1000
    adduser -u 1000 -D -s /bin/sh ciadpi

ENTRYPOINT ["/entrypoint.sh"]   