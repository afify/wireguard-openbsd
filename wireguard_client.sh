#!/bin/sh

# wireguard_client.sh
# Written for OpenBSD 7.4

if [ "$(id -u || true)" -ne 0 ]; then
	printf "%s\n" "This script must be run as root" >&2; exit 1
fi

if [ -z "$1" ]; then
  printf "%s\n" "Usage: $0 <client>" >&2; exit 1
fi

client=$1
server_ip=$(curl ipinfo.io/ip)
interface="wg0"
config_file="/etc/wireguard/${interface}.conf"
clients_dir="/etc/wireguard/clients"
server_port=$(grep "ListenPort" "${config_file}" | awk '{print $3}')

last_ip=$(tail -n 1 "${config_file}" |\
		grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
new_ip=$(printf "%s" "${last_ip}" | awk -F. '{print $1"."$2"."$3"."$4+1}')
client_ip="${new_ip}/32"

mkdir -p "${clients_dir}"
cd "${clients_dir}" || exit 1
server_public=$(cat "../public.key")

umask 077
wg genkey > "${client}_private.key"
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

cat >> "${config_file}" << EOF

# client [${client}]
[Peer]
PublicKey = ${client_public}
AllowedIPs = ${client_ip}
EOF
umask 022

sh /etc/netstart "${interface}"
qrencode --read-from="${client}.conf" --type=UTF8 --level=M
printf "\n"
cat "${clients_dir}/${client}.conf"
