### [Pull from Docker Hub](https://hub.docker.com/r/wiktorbgu/byedpi-hev-socks5-tunnel)

## Mikrotik settings  
### Подробная инструкция настройки Mikrotik [habr.ru](https://habr.com/ru/articles/838452/) или [web.archive.org](https://web.archive.org/web/20241106205452/https://habr.com/ru/articles/838452/)
---

```
/interface/bridge add name=Bridge-Docker port-cost-mode=short
/ip/address add address=192.168.254.1/24 interface=Bridge-Docker network=192.168.254.0
/interface/veth add address=192.168.254.2/24 gateway=192.168.254.1 name=BYEDPI-TUN
/interface/bridge/port add bridge=Bridge-Docker interface=BYEDPI-TUN
```

### change path /usb1 to your actual path
```
/container/config set registry-url=https://registry-1.docker.io tmpdir=/usb1/docker/pull 

/container/envs/ add key=LOCAL_ROUTE name=byedpi-tun value="ip r a 192.168.0.0/16 via 192.168.254.1;ip r a 10.0.0.0/8 via 192.168.254.1;ip r a 172.16.0.0/12 via 192.168.254.1"
/container/add remote-image=wiktorbgu/byedpi-hev-socks5-tunnel interface=BYEDPI-TUN cmd="--disorder 1 --auto=torst --tlsrec 1+s" root-dir=/usb1/docker/byedpi-hev-socks5-tunnel start-on-boot=yes envlist=byedpi-tun
```
### Table routing

```
/routing/table add disabled=no fib name=dpi_mark 

/ip/route add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=192.168.254.2%Bridge-Docker pref-src="" routing-table=dpi_mark scope=30 suppress-hw-offload=no target-scope=10
```
### Route address list to BYEDPI TUNNEL

```

/ip firewall mangle add action=mark-routing chain=prerouting comment="List DNS FWD route to byedpi tunnel" dst-address-list=za_dpi_FWD in-interface-list=LAN new-routing-mark=dpi_mark passthrough=no
```
### RUN container and enjoy! =)
```
/container start [find interface=BYEDPI-TUN]
```
---
### [GitHub](https://github.com/wiktorbgu/byedpi-hev-socks5-tunnel)