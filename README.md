# Wireguard config for OpenBSD

## Server
```sh
pkg_add wireguard-tools
pkg_add qrencode #optional
sh wireguard_server.sh
```
### For each client
```sh
sh wireguard_client.sh client_name
```
- config file will be generated at /etc/wireguard/clients/client_name.conf
- qr code will be generated


## Client
```sh
wg-quick up client_name.conf
```

### IOS
https://apps.apple.com/us/app/wireguard/id1441195209 (App Store)
https://apps.apple.com/us/app/wireguard/id1451685025 (Mac App Store)


### Android
https://play.google.com/store/apps/details?id=com.wireguard.android
https://f-droid.org/en/packages/com.wireguard.android/
