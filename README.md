# Wireguard config for OpenBSD

## Server (Automatic)
```sh
sh wireguard_server.sh
```

## Server (Command line switches)
```sh
sh wireguard_server.sh --network=192.168.0.1 --port=51111
```

## Server (Interactive)
```sh
sh wireguard_server.sh --interactive

```
## For each client
```sh
sh wireguard_client.sh client_name
```

- config file will be generated at /etc/wireguard/clients/client_name.conf
- qr code will be generated

### Client-side configuration 

## wg-quick on *nix
```sh
wg-quick up client_name.conf
```

## IOS
https://apps.apple.com/us/app/wireguard/id1441195209 (App Store)
https://apps.apple.com/us/app/wireguard/id1451685025 (Mac App Store)

Scan QR code


## Android
https://play.google.com/store/apps/details?id=com.wireguard.android
https://f-droid.org/en/packages/com.wireguard.android/

Scan QR code

### CAVEATS:

- In tmux the generated QR code may have some display issues in your terminal. If you're encountering a bunch of lines instead of a QR code, try running outside of a tmux session.
