#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root"
	exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <client>"
  exit 1
fi

client=$1
server_ip=$(curl ipinfo.io/ip)
interface="wg0"
config_file="/etc/wireguard/${interface}.conf"
clients_dir="/etc/wireguard/clients"
server_port=$(grep "ListenPort" ${config_file} | awk '{print $3}')

last_ip=$(tail -n 1 ${config_file} |\
		grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
new_ip=$(echo "$last_ip" | awk -F. '{print $1"."$2"."$3"."$4+1}')
client_ip="${new_ip}/32"

mkdir -p ${clients_dir}
cd ${clients_dir} || exit
server_public=$(cat "../public.key")
umask 077 && wg genkey > "${client}_private.key"
wg pubkey < "${client}_private.key" > "${client}_public.key"

client_private=$(cat "${client}_private.key")
client_public=$(cat "${client}_public.key")

cat > "${client}.conf" << EOF
[Interface]
PrivateKey = ${client_private}
Address=${client_ip}
DNS = 9.9.9.9

# Server
[Peer]
PublicKey = ${server_public}
Endpoint = ${server_ip}:${server_port}
AllowedIPs = ::/0, 0.0.0.0/0
PersistentKeepalive = 25
EOF

cat >> ${config_file} << EOF

# client [${client}]
[Peer]
PublicKey = ${client_public}
AllowedIPs = ${client_ip}
EOF

qrencode --read-from="${client}.conf" --type=UTF8 --level=M

sh /etc/netstart ${interface}
cat "${clients_dir}/${client}.conf"
