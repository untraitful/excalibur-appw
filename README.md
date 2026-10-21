# Excalibur

A monochrome Android dashboard for a homelab: one screen of links to every
service, with live up/down status, and a built-in SSH terminal. No Tailscale,
Twingate or other VPN client needed on the phone.

```
SERVICES   grid of links grouped by category, status per tile, LAN/WAN aware
TERMINAL   native SSH (key or password), extra-keys row, host key pinning
SETTINGS   network mode, export/import of your config as JSON
```

## Install

Every push builds an APK with GitHub Actions.

1. Open the repo's **Actions** tab, then the latest **Build APK** run.
2. Download the `excalibur-apk` artifact, unzip, copy `app-release.apk` to the phone.
3. Open it and allow "install unknown apps" for your file manager.

Push a tag like `v1.0.0` to get the APK attached to a GitHub Release instead.

The release build is signed with Flutter's debug key, which is fine for
sideloading your own app. To build locally: install Flutter, then
`flutter build apk --release`.

## Using it

**Services.** Tap `+`, give it a name, a public URL and optionally a LAN URL.
In *Auto* mode the app tries the LAN URL first (1.5 s timeout) and falls back
to the public one, so the same tile works at home and away. Tap a tile to open
it in the in-app browser; long-press for edit / open externally / copy / delete.
Turn on *Open in external browser* for services that use passkeys or SSO flows
the embedded web view can't handle.

Status is checked on launch, every 60 s and on pull-to-refresh. Any HTTP
response counts as up (a login page or 401 still means the service is alive);
5xx is shown as degraded, no response as offline.

**Terminal.** Add a host with a private key (recommended) or password.
Credentials are stored in Android's encrypted storage (Keystore) and are never
included in exports. The first connection shows the server's SHA256 host key
fingerprint for you to confirm; after that a changed key triggers a warning.
Compare against the server with:

```sh
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Set *Run on connect* to `tmux new -A -s main` to land in a persistent session
that survives dropped mobile connections.

The row above the keyboard has ESC, TAB, sticky CTRL/ALT (tap CTRL then `c`
for ^C), arrows, HOME/END/PGUP/PGDN and paste. Long-press text to select it,
then use the copy button in the top bar.

## Reaching the homelab without a VPN client

The app connects to plain URLs and SSH endpoints, so how you expose them is up
to you. Pick one or combine them.

### Option A: Cloudflare Tunnel (web services, no open ports)

Run `cloudflared` on any machine in the lab. It dials out to Cloudflare, so
nothing is port-forwarded on your router.

```yaml
# /etc/cloudflared/config.yml
tunnel: <tunnel-id>
credentials-file: /etc/cloudflared/<tunnel-id>.json
ingress:
  - hostname: proxmox.example.com
    service: https://192.168.1.10:8006
    originRequest: { noTLSVerify: true }
  - hostname: jellyfin.example.com
    service: http://192.168.1.20:8096
  - hostname: term.example.com
    service: http://localhost:7681        # ttyd, see below
  - service: http_status:404
```

Then put **Cloudflare Access** (Zero Trust > Access > Applications) in front of
each hostname with an email one-time-PIN or GitHub login policy. The in-app
browser keeps the Access cookie, so you log in once.

Native SSH over Cloudflare needs `cloudflared` on the client, which Android
doesn't have. For a terminal through the tunnel, run
[ttyd](https://github.com/tsl0922/ttyd) on the server
(`ttyd -W -i lo -p 7681 login`) and add `https://term.example.com` as a
service in Excalibur. Keep it behind Access.

### Option B: Direct SSH with port forwarding (native terminal)

Forward one external port on the router (e.g. `2222`) to the SSH server and
harden it before you do:

```sh
# /etc/ssh/sshd_config.d/hardening.conf
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
AllowUsers you
MaxAuthTries 3
```

Add `fail2ban` or CrowdSec, generate a key just for the phone
(`ssh-keygen -t ed25519 -f phone`), put `phone.pub` in `~/.ssh/authorized_keys`
and paste `phone` into the app. Use a dynamic DNS name if your IP changes.
From this one box you can `ssh` onward to everything else.

### Option C: Reverse proxy on 443 (web services)

Forward 443 to Caddy, Traefik or Nginx Proxy Manager with automatic HTTPS and
put an auth layer (Authelia, Authentik) in front of every app that doesn't
have its own login. Use the public hostnames as the service URLs and the
internal `http://ip:port` addresses as LAN URLs.

### Option D: Plain WireGuard

If you change your mind about VPNs, WireGuard on your router (no third party
involved) plus the official WireGuard app makes every LAN URL reachable. Set
Excalibur to *Always LAN*.

**Do not** port-forward admin UIs (Proxmox, router, NAS) straight to the
internet without an auth layer in front.

## Backup

Settings > *Export to clipboard* copies your services and hosts as JSON
(without passwords or keys). *Import from clipboard* replaces them. Handy for
setting up a second phone or keeping the config in a password manager.

## Project layout

```
lib/
  main.dart                  app shell and bottom navigation
  theme.dart                 black/white Material theme and greyscale terminal palette
  models.dart                Service, SshHost, icon set
  store.dart                 persistence (shared_preferences + secure storage)
  health.dart                reachability checks and LAN/WAN selection
  terminal_keys.dart         sticky CTRL/ALT handling
  screens/                   services, web view, hosts, terminal, settings
```
