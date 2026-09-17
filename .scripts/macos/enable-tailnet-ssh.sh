#!/bin/bash
# Enable macOS Remote Login (sshd) and restrict it to the Tailscale tailnet.
#
# Why this exists: this Mac runs the sandboxed Tailscale GUI build
# (io.tailscale.ipn.macsys), which cannot run the Tailscale SSH server
# (`tailscale set --ssh` refuses). So we use Apple's sshd instead, and close
# the holes that opens:
#   1. Remote Login on            -> launchd listens on tcp/22 on EVERY interface
#   2. Access ACL = only $SSH_USER -> "Allow access for: Only these users"
#   3. sshd drop-in               -> AllowUsers, and no auth methods at all for
#                                    connections not arriving from the tailnet
#   4. pf firewall                -> tcp/22 accepted only when addressed to this
#                                    node's tailnet IPs (i.e. arrived via the
#                                    Tailscale tunnel) or loopback; everything
#                                    else gets an RST. Persisted via LaunchDaemon.
#
# Idempotent: safe to re-run (e.g. after a macOS update rewrites /etc/pf.conf).
# Run as:  sudo ~/dotfiles/.scripts/macos/enable-tailnet-ssh.sh
set -euo pipefail

SSH_USER="${SUDO_USER:-quy}"
ANCHOR_NAME="ssh-tailnet"
ANCHOR_FILE="/etc/pf.anchors/${ANCHOR_NAME}"
SSHD_DROPIN="/etc/ssh/sshd_config.d/050-tailnet-only.conf"
DAEMON_LABEL="local.pf.${ANCHOR_NAME}"
DAEMON_PLIST="/Library/LaunchDaemons/${DAEMON_LABEL}.plist"
TS_RANGE4="100.64.0.0/10"
TS_RANGE6="fd7a:115c:a1e0::/48"

[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
[[ "$(uname)" == Darwin ]] || { echo "macOS only" >&2; exit 1; }

TS_IP4="$(/usr/local/bin/tailscale ip -4)"
TS_IP6="$(/usr/local/bin/tailscale ip -6)"
[[ -n "$TS_IP4" ]] || { echo "tailscale reports no IPv4 address; is it connected?" >&2; exit 1; }
echo "==> tailnet user=$SSH_USER ip4=$TS_IP4 ip6=$TS_IP6"

# --- 1. Remote Login ---------------------------------------------------------
echo "==> enabling Remote Login"
out="$(systemsetup -setremotelogin on 2>&1 || true)"
echo "    systemsetup: $out"
if echo "$out" | grep -qi 'full disk access'; then
  # Ventura+ gates systemsetup behind FDA for the calling terminal; the launchd
  # route is what the Sharing pane toggles under the hood anyway.
  echo "    falling back to launchctl"
  launchctl enable system/com.openssh.sshd
  launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
fi
launchctl print system/com.openssh.sshd >/dev/null 2>&1 \
  && echo "    com.openssh.sshd is loaded" \
  || { echo "    ERROR: com.openssh.sshd not loaded" >&2; exit 1; }

# Host keys are normally generated lazily on first connection; make them now so
# `sshd -t` can validate the config below.
ssh-keygen -A >/dev/null
echo "    host keys: $(ls /etc/ssh/ssh_host_*_key.pub | xargs -n1 basename | tr '\n' ' ')"

# --- 2. "Allow access for: Only these users" ---------------------------------
echo "==> restricting SSH access ACL to $SSH_USER"
# Default nests the admin group; replace with just the one user.
dseditgroup -o edit -d admin -t group com.apple.access_ssh 2>/dev/null || true
dseditgroup -o edit -a "$SSH_USER" -t user com.apple.access_ssh
dseditgroup -o checkmember -m "$SSH_USER" com.apple.access_ssh

# --- 3. sshd drop-in ---------------------------------------------------------
echo "==> writing $SSHD_DROPIN"
cat > "$SSHD_DROPIN" <<CONF
# Managed by ~/dotfiles/.scripts/macos/enable-tailnet-ssh.sh
# Only this account may log in over SSH.
AllowUsers $SSH_USER

# Connections that did NOT arrive from the tailnet get no authentication
# methods at all (defense in depth behind the pf rule; pf already RSTs them).
Match Address 0.0.0.0/0,::/0,!$TS_RANGE4,!$TS_RANGE6
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PubkeyAuthentication no
CONF
chmod 644 "$SSHD_DROPIN"
/usr/sbin/sshd -t && echo "    sshd config OK"
echo "    effective auth from tailnet (100.102.247.117):  password=$(/usr/sbin/sshd -T -C user=$SSH_USER,host=x,addr=100.102.247.117,laddr=$TS_IP4,lport=22 | awk '/^passwordauthentication/{print $2}') pubkey=$(/usr/sbin/sshd -T -C user=$SSH_USER,host=x,addr=100.102.247.117,laddr=$TS_IP4,lport=22 | awk '/^pubkeyauthentication/{print $2}')"
echo "    effective auth from elsewhere (192.168.1.50):  password=$(/usr/sbin/sshd -T -C user=$SSH_USER,host=x,addr=192.168.1.50,laddr=192.168.1.2,lport=22 | awk '/^passwordauthentication/{print $2}') pubkey=$(/usr/sbin/sshd -T -C user=$SSH_USER,host=x,addr=192.168.1.50,laddr=192.168.1.2,lport=22 | awk '/^pubkeyauthentication/{print $2}')"

# --- 4. pf: tcp/22 only via the tailnet --------------------------------------
echo "==> writing $ANCHOR_FILE"
cat > "$ANCHOR_FILE" <<PF
# Managed by ~/dotfiles/.scripts/macos/enable-tailnet-ssh.sh
# Accept SSH only when it is addressed to this node's tailnet IPs (which can only
# be reached through the Tailscale tunnel) or to loopback. Everything else on
# tcp/22 -- untrusted Wi-Fi, hotel LANs, IPv6 link-local -- gets a RST.
pass in quick on lo0 proto tcp to any port 22
pass in quick inet  proto tcp from $TS_RANGE4 to $TS_IP4 port 22
PF
[[ -n "$TS_IP6" ]] && echo "pass in quick inet6 proto tcp from $TS_RANGE6 to $TS_IP6 port 22" >> "$ANCHOR_FILE"
echo "block return in quick proto tcp from any to any port 22" >> "$ANCHOR_FILE"
chmod 644 "$ANCHOR_FILE"

if ! grep -q "anchor \"$ANCHOR_NAME\"" /etc/pf.conf; then
  echo "==> registering anchor in /etc/pf.conf"
  printf '\n# SSH reachable only over the tailnet (see %s)\nanchor "%s"\nload anchor "%s" from "%s"\n' \
    "$ANCHOR_FILE" "$ANCHOR_NAME" "$ANCHOR_NAME" "$ANCHOR_FILE" >> /etc/pf.conf
fi
# Syntax-check before loading (exit status; macOS pfctl always prints ALTQ and
# "Use of -f option" notices on stderr, so output is not a usable signal).
# Loading a broken file would leave the old ruleset, with no port-22
# restriction, in place.
if ! pf_check="$(pfctl -n -f /etc/pf.conf 2>&1)"; then
  echo "$pf_check" >&2
  echo "    ERROR: /etc/pf.conf failed to parse; NOT loading. sshd is still open on all interfaces." >&2
  exit 1
fi
pfctl -E -f /etc/pf.conf >/dev/null 2>&1 || { echo "    ERROR: pfctl -E -f /etc/pf.conf failed" >&2; exit 1; }
echo "    pf rules loaded"

echo "==> installing $DAEMON_PLIST (re-applies pf rules at boot)"
cat > "$DAEMON_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$DAEMON_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/sbin/pfctl</string>
    <string>-E</string>
    <string>-f</string>
    <string>/etc/pf.conf</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
PLIST
chown root:wheel "$DAEMON_PLIST"; chmod 644 "$DAEMON_PLIST"
launchctl bootout system "$DAEMON_PLIST" 2>/dev/null || true
launchctl bootstrap system "$DAEMON_PLIST"

# --- verify -------------------------------------------------------------------
echo "==> verification"
pfctl -s info 2>/dev/null | head -1
echo "    pf rules for port 22:"
pfctl -a "$ANCHOR_NAME" -s rules 2>/dev/null | sed 's/^/      /'
if nc -z -w2 127.0.0.1 22 2>/dev/null; then echo "    sshd answering on loopback: yes"; else echo "    sshd answering on loopback: NO" >&2; fi
# Note: connecting to this Mac's own LAN IP from this Mac goes over lo0 (see
# `netstat -rn`), so it is passed by the loopback rule and proves nothing.
# The block can only be tested from another host on the same network.
lan_ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
[[ -n "$lan_ip" ]] && echo "    LAN ip $lan_ip: test from another machine, e.g.  nc -zv -w3 $lan_ip 22  (expect refused)"
echo
echo "Done. From leopard:  ssh $SSH_USER@devbook.tail77ce1b.ts.net"
