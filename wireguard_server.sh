#!/bin/sh

# wireguard_server.sh
# Written for OpenBSD 7.4

# shellcheck source=./network.sh
. "./network.sh"

if [ "$(id -u || true)" -ne 0 ]; then
  printf "%s\n" "This script must be run as root"; exit 1
fi

server_port=""
dns="9.9.9.9"
vpn_gateway="10.0.23.1"

# flag management
while [ $# -gt 0 ]; do
  for flag in "$@"; do
    case "$flag" in
      --port=*) validateport "${flag##--port=}"; shift;;
      --network=*) gatewayvalidateclassa "${flag##--network=}"; shift;;
      --dns=*) validateip "${flag##--dns=}"; validatedns "${flag##--dns=}"; shift;;
      *) printf "Flag %s not recognized\n" "${1}">&2; exit 1;;
    esac
  done
done

if [ -z "${server_port}" ]; then
  randomport
fi

printf "Choosing internal VPN gateway IP: %s and external port: %s with primary DNS: %s\n" "${vpn_gateway}" "${server_port}" "${dns}"

# wireguard setup
interface="wg0"
config_file="/etc/wireguard/${interface}.conf"
pkg_add -u && pkg_add wireguard-tools libqrencode curl &&
sysctl net.inet.ip.forwarding=1
sysctl net.inet6.ip6.forwarding=1
printf "%s\n" "net.inet.ip.forwarding=1" >> /etc/sysctl.conf
printf "%s\n" "net.inet6.ip6.forwarding=1" >> /etc/sysctl.conf
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
cd /etc/wireguard || exit 1
umask 077
wg genkey > private.key
chmod 600 private.key
wg pubkey < private.key > public.key
server_private=$(cat "private.key")

cat > "${config_file}" << EOF
[Interface]
PrivateKey = ${server_private}
ListenPort = ${server_port}
# ${vpn_gateway}
EOF

cat > /etc/hostname."${interface}" << EOF
inet ${vpn_gateway} 255.255.255.0 NONE
up

!/usr/local/bin/wg setconf ${interface} ${config_file}
EOF

# pf
cat >> /etc/pf.conf << EOF
pass in on ${interface}
pass in inet proto udp from any to any port ${server_port}
pass out on egress inet from (${interface}:network) nat-to (vio0:0)
EOF
umask 022

sh /etc/netstart "${interface}"
pfctl -f /etc/pf.conf

unset gatewayvalidateclassa
unset randomport
unset validatedns
