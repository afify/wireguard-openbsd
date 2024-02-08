#!/bin/sh

# network.sh
# Written for OpenBSD 7.4

# gatewayvalidateclassa validates a given input address
# in environment variable $vpn_gateway and makes sure that
# it is a valid class A gateway IP address
gatewayvalidateclassa() {
  # these awk oneliners filter for class A networks
  valid_192_ip=$(printf "%s" "${1}" | \
    awk -F"\." ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 == 192 && $2 == 168 && $3 <= 255 && $4 <= 255 && $4 != 0 ')
  valid_10_ip=$(printf "%s" "${1}" | \
    awk -F"\." ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 == 10 && $2 <= 255 && $3 <= 255 && $4 <= 255 && $4 != 0 ')
  valid_172_ip=$(printf "%s" "${1}" | \
    awk -F"\." ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 == 172 && $2 <= 255 && $3 <= 255 && $4 <= 255 && $4 != 0 ')

  # if none pass the above validators then we don't have a class A IP address
  if [ "${valid_192_ip}" = "" ] && [ "${valid_10_ip}" = "" ] && [ "${valid_172_ip}" = "" ]; then
    printf "Error: Gateway IP address %s invalid. Please enter a valid class A gateway IP address\n" "${1}" >&2
    exit 1
  fi
  vpn_gateway="${1}"
}

validateip() {
  valid_ip=$(printf "%s" "${1}" | \
    awk -F"\." ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255 && $4 != 0 ')
  if [ -z ${valid_ip} ]; then
    printf "Error: IP address %s invalid. Please enter a valid IP address.\n" "${1}" >&2; exit 1
  fi
}

validatedns() {
  nslookup google.com ${1} > /dev/null 2>&1
  if [ "$?" != 0 ]; then
    printf "IP address for DNS %s failed nslookup. Please enter a working DNS server.\n" "${1}" >&2; exit 1
  fi
  dns="${1}"
}

# randomport() selects a random port from 50000 to 59999,
# excluding the default wireguard port 51820
randomport() {
printf "%s\n" "Selecting random port between 50000-59999"
  while true; do
    random_digits=$(jot -r 1 50000 59999 | cut -c 2-)
    if [ "${random_digits}" -ne 51820 ]; then
      server_port="5${random_digits}"
      break
    fi
  done
}

validateport() {
if [ "${1}" -gt 1 ] && [ "${1}" -le 65535 ]; then
  server_port="${1}"
else
  printf "%s\n" "invalid port" >&2; exit 1
fi
}

export gatewayvalidateclassa
export randomport
export validatedns
