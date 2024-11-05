#!/bin/sh

TUN="${TUN:-tun0}"
MTU="${MTU:-9000}"
IPV4="${IPV4:-198.18.0.1}"
IPV6="${IPV6:-}"

MARK="${MARK:-438}"

SOCKS5_UDP_MODE="${SOCKS5_UDP_MODE:-udp}"
LOCAL_ROUTE="${LOCAL_ROUTE:-}"
LOG_LEVEL="${LOG_LEVEL:-warn}"

config_file() {
  cat > /hs5t.yml << EOF
misc:
  log-level: '${LOG_LEVEL}'
tunnel:
  name: '${TUN}'
  mtu: ${MTU}
  ipv4: '${IPV4}'
  ipv6: '${IPV6}'
  post-up-script: '/route.sh'
socks5:
  address: '127.0.0.1'
  port: 1080
  udp: '${SOCKS5_UDP_MODE}'
  mark: ${MARK}
EOF
}

config_route() {
  echo "#!/bin/sh" > /route.sh
  chmod +x /route.sh
  echo "ip rule add from all uidrange 1000-1000 lookup 110 pref 28000" >> /route.sh
  echo "ip route flush table 110" >> /route.sh
  echo "ip route add default via $(ip route | awk '/default/ && /eth0/ {print $3}') dev eth0 metric 50 table 110" >> /route.sh
  echo "ip route del default" >> /route.sh
  echo "ip route add default via ${IPV4} dev ${TUN} metric 1" >> /route.sh
  echo "ip route add default via $(ip route | awk '/default/ && /eth0/ {print $3}') dev eth0 metric 10" >> /route.sh
  echo "${LOCAL_ROUTE}" >> /route.sh
}

run() {
  config_file
  config_route
  echo "echo 1 > /success" >> /route.sh
  hev-socks5-tunnel /hs5t.yml &
  su - ciadpi -c "/opt/byedpi/ciadpi $*"

}

run "$@" || exit 1
