#!/bin/sh

# network.sh
# Written for OpenBSD 7.4

# gatewayvalidateclassa validates a given input address
# in environment variable $vpn_gateway and makes sure that
# it is a valid class A gateway IP address
gatewayvalidateclassa() {
  # these awk oneliners filter for class A networks
  valid_192_ip=$(printf "%s" "${vpn_gateway}" | \
    awk -F"\." ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 == 192 && $2 == 168 && $3 <= 255 && $4 <= 255 && $4 != 0 ')
  valid_10_ip=$(printf "%s" "${vpn_gateway}" | \
    awk -F"\." ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 == 10 && $2 <= 255 && $3 <= 255 && $4 <= 255 && $4 != 0 ')
  valid_172_ip=$(printf "%s" "${vpn_gateway}" | \
    awk -F"\." ' $0 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ && $1 == 172 && $2 <= 255 && $3 <= 255 && $4 <= 255 && $4 != 0 ')

  # if none pass the above validators then we don't have a class A IP address
  if [ "${valid_192_ip}" = "" ] && [ "${valid_10_ip}" = "" ] && [ "${valid_172_ip}" = "" ]; then
    printf "Error: Gateway IP address %s invalid. Please enter a valid class A gateway IP address\n" "${vpn_gateway}" >&2
    exit 1
  fi
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

# customport() selects a custom port from 1 to 65535
customport() {
  while true; do
    printf "%s\n" "Enter a custom port from 1 to 65535: "
    read -r port
    if [ "${port}" -gt 1 ] && [ "${port}" -le 65535 ]; then
      server_port="${port}"
      break
    else
      printf "%s\n" "Error: Port out of acceptable range." >&2
    fi
  done
}

# randomportcustomrange() selects a random port between a user
# provided low to high range value.
randomportcustomrange() {
  while true; do
    printf "%s\n" "Enter a port range start from 1024 to 65536: "
    read -r portrangestart
    if [ "${portrangestart}" -ge 1024 ] && \
       [ "${portrangestart}" -le 65536 ]; then
      printf "%s to 36665\n" "Enter a port range end from ${portrangestart}"
      read -r portrangeend
      if [ "${portrangeend}" -gt "${portrangestart}" ] && \
         [ "${portrangeend}" -gt 1024 ] && \
         [ "${portrangeend}" -le 65536 ]; then
        while true; do
          random_digits=$(jot -r 1 "${portrangestart}" "${portrangeend}")
          if [ "${random_digits}" -ne 51820 ]; then
            server_port="${random_digits}"
            break
          fi
        done
      break
      else
        printf "%s\n" "Error: Port range end out of range. Please enter a port range end from 1024 to 65536"
      fi
    else
      printf "%s\n" "Error: Port range start out of range. Please enter a port range start from 1024 to 65536"
    fi
  done
}

# chooseport() starts the interactive port selection.
chooseport() {
  while true; do
cat <<EOF
Choose an option for which port for this server to use:
1) Random port between 50000-59999 (Default)
2) Default port (51820)
3) Default TLS port (443)
4) Custom port
5) Custom random port in range
EOF
  printf "%s\n" "Select a number or hit enter for default:"
  read -r option
    case "${option}" in
      1) randomport;;
      2) server_port=51820;;
      3) server_port=443;;
      4) customport;;
      5) randomportcustomrange;;
      "") randomport; printf "%s\n" "No option selected, using random port between 50000-59999";; 
      *) printf "%s\n" "Please select a number betweeen 1 and 5";;
    esac
    if [ "${server_port}" -ne "" ]; then
      printf "Selecting port %s\n" "${server_port}"
      break
    fi
  done
}

# choosenetwork() starts the interactive gateway selection
choosenetwork() {
  printf "%s\n" "Enter a gateway IP address:"
  read -r vpn_gateway
  gatewayvalidateclassa
}

interactive() {
  if [ "${vpn_gateway}" = "10.0.23.1" ]; then
    choosenetwork
  fi
  if [ "${server_port}" = "" ]; then
    chooseport  
  fi
}

export gatewayvalidateclassa
export interactive
export randomport
