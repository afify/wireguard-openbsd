#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root"
	exit 1
fi

random_digits=$(LC_ALL=C tr -dc 0-9 </dev/urandom | head -c 4)
server_port="5${random_digits}"
interface="wg0"
config_file="/etc/wireguard/${interface}.conf"

pkg_add wireguard-tools
sysctl net.inet.ip.forwarding=1
sysctl net.inet6.ip6.forwarding=1
echo "net.inet.ip.forwarding=1" >> /etc/sysctl.conf
echo "net.inet6.ip6.forwarding=1" >> /etc/sysctl.conf
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
cd /etc/wireguard || exit
wg genkey > private.key
chmod 600 private.key
wg pubkey < private.key > public.key
server_private=$(cat "private.key")

cat > ${config_file} << EOF
[Interface]
PrivateKey = ${server_private}
ListenPort = ${server_port}
EOF

cat > /etc/hostname.${interface} << EOF
inet 10.0.0.1 255.255.255.0 NONE
up

!/usr/local/bin/wg setconf ${interface} ${config_file}
EOF

# pf
cat >> /etc/pf.conf << EOF
pass in on ${interface}
pass in inet proto udp from any to any port ${server_port}
pass out on egress inet from (${interface}:network) nat-to (vio0:0)
EOF

sh /etc/netstart ${interface}
pfctl -f /etc/pf.conf
