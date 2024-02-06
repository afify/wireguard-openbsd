#!/bin/sh

# wireguard_server.sh
# Written for OpenBSD 7.4

# shellcheck source=./network.sh
. "./network.sh"

if [ "$(id -u || true)" -ne 0 ]; then
	printf "%s\n" "This script must be run as root"; exit 1
fi

interactive=${interactive:-0}

server_port=""
vpn_gateway="10.0.23.1"

# flag management
while test $# -gt 0; do
	# test if we're using interactive mode first
	if test "${1}" = "--interactive"; then interactive=1; shift; continue; fi
	if test "${1}" = "--i"; then interactive=1; shift; continue; fi
	# then test if port/gateway for network is set on command line
  case "$1" in
  	--port=*) if [ "${1##--port=}" -gt 1 ] && [ "${1##--port=}" -le 65535 ]; then
  							server_port="${1##--port=}"
  						else
  							printf "%s\n" "invalid port" >&2; exit 1
  						fi
  						if [ "${2##--network}" != "" ]; then
								vpn_gateway="${2##--network=}" gatewayvalidateclassa; break
							fi; shift; continue; break ;;
  	--network=*) vpn_gateway="${1##--network=}" gatewayvalidateclassa
 							if [ "${2##--port=}" -gt 1 ] && [ "${2##--port=}" -le 65535 ]; then
    						server_port="${2##--port=}"
    					elif [ "${2##--port=}" = "" ]; then
    						randomport
    					else
    						printf "%s\n" "invalid port" >&2; exit 1
    					fi; shift; continue; break;;
  	*) printf "%s\n" "Flag not recognized">&2; exit 1;;
  esac
  printf "%s\n" "Unknown option or flag $1" >&2; exit 1
done

printf "Choosing internal VPN gateway IP: %s and external port: %s\n" "${vpn_gateway}" "${server_port}"

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
unset interactive
unset randomport
