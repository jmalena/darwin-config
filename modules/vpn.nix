{ lib, pkgs, ... }:

let
  tunnel = "proton";
  configFile = "/etc/wireguard/${tunnel}.conf";
  anchor = "vpn-killswitch";

  # Everything below /var/run is cleared on reboot, so a stale bypass or a
  # cached endpoint can never outlive the session that created it.
  nameFile = "/var/run/wireguard/${tunnel}.name";
  endpointFile = "/var/run/vpn-endpoint";
  bypassFile = "/var/run/vpn-bypass";
  pendingRules = "/var/run/vpn-rules.new";
  loadedRules = "/var/run/vpn-rules.loaded";

  bypassSeconds = 900;
  staleHandshake = 300;

  # Apple's stock main ruleset with one anchor point of ours appended. Loading a
  # main ruleset drops the anchors macOS services insert at runtime — Internet
  # Sharing's NAT among them — so this is loaded only when our anchor point is
  # missing, which in practice means once per boot. Everything after that loads
  # rules *into* the anchor and leaves the rest of the ruleset alone.
  pfRuleset = pkgs.writeText "pf-${anchor}.conf" ''
    scrub-anchor "com.apple/*"
    nat-anchor "com.apple/*"
    rdr-anchor "com.apple/*"
    dummynet-anchor "com.apple/*"
    anchor "com.apple/*"
    load anchor "com.apple" from "/etc/pf.anchors/com.apple"

    anchor "${anchor}"
  '';

  vpnBypass = pkgs.writeShellScriptBin "vpn-bypass" ''
    if [ "$(/usr/bin/id -u)" -ne 0 ]; then
      echo "vpn-bypass: run with sudo" >&2
      exit 1
    fi

    case "''${1:-on}" in
      on)
        /usr/bin/touch ${bypassFile}
        echo "kill switch off for ${toString (bypassSeconds / 60)} minutes — sign in to the portal, then: sudo vpn-bypass off"
        ;;
      off)
        /bin/rm -f ${bypassFile}
        echo "kill switch back on"
        ;;
      *)
        echo "usage: vpn-bypass [on|off]" >&2
        exit 2
        ;;
    esac
  '';
in
{
  environment.systemPackages = [ pkgs.wireguard-tools vpnBypass ];

  # The Proton profile carries a private key, so it is placed by hand rather
  # than declared here: anything in the nix store is world-readable, and this
  # repo is one push away from being public. Download it from
  # account.protonvpn.com > Downloads > WireGuard configuration.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    /bin/mkdir -p /etc/wireguard
    /bin/chmod 700 /etc/wireguard
  '';

  # Tunnel and kill switch live in one loop because the rules have to name the
  # tunnel's interface and its endpoint, and neither is known until the
  # handshake has happened.
  launchd.daemons.vpn-tunnel = {
    script = ''
      export PATH=/usr/bin:/bin:/usr/sbin:/sbin

      wg=${pkgs.wireguard-tools}/bin/wg
      wgQuick=${pkgs.wireguard-tools}/bin/wg-quick

      # Reloading pf on every pass would be pointless churn, so rules are only
      # handed to pfctl when they differ from what is already loaded. Empty
      # input means flush.
      applyRules() {
        /bin/cat > ${pendingRules}

        if /usr/bin/cmp -s ${pendingRules} ${loadedRules}; then
          /bin/rm -f ${pendingRules}
          return
        fi

        if [ -s ${pendingRules} ]; then
          /sbin/pfctl -a ${anchor} -f ${pendingRules} 2>/dev/null
        else
          /sbin/pfctl -a ${anchor} -F rules 2>/dev/null
        fi

        /bin/mv ${pendingRules} ${loadedRules}
      }

      # Called with the tunnel interface when one is up, and with nothing while
      # reconnecting — the endpoint stays reachable either way, so a reconnect
      # is not a hole. With no endpoint cached yet there is nothing to allow,
      # and blocking would only cut off the network needed to reach Proton.
      killSwitch() {
        tun=$1

        if [ ! -s ${endpointFile} ]; then
          applyRules < /dev/null
          return
        fi

        read -r endpoint < ${endpointFile}
        port=''${endpoint##*:}
        host=''${endpoint%:*}
        host=''${host#\[}
        host=''${host%\]}

        {
          echo "pass out quick on lo0 all"
          [ -n "$tun" ] && echo "pass out quick on $tun all"

          # AirDrop and Continuity run peer-to-peer over these links and never
          # through the tunnel; the kill switch must not take them down.
          echo "pass out quick on awdl0 all"
          echo "pass out quick on llw0 all"

          echo "pass out quick proto udp from any to $host port $port"
          echo "pass out quick proto udp from any port 68 to any port 67"

          # The local segment: router, DHCP, mDNS, and whatever Internet Sharing
          # has handed addresses to.
          echo "pass out quick inet from any to { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 224.0.0.0/4, 255.255.255.255 }"
          echo "pass out quick inet6 from any to { fe80::/10, ff00::/8 }"

          # Everything else, IPv6 included — the usual way a tunnel leaks.
          echo "block drop out all"
        } | applyRules
      }

      tunnelUp() {
        [ -s ${nameFile} ] || return 1
        read -r iface < ${nameFile}
        [ -n "$iface" ] || return 1
        /sbin/ifconfig "$iface" >/dev/null 2>&1 || return 1

        # Proton's profile does not always set a keepalive, and without one an
        # idle tunnel stops rehandshaking and looks dead. Asking for one makes
        # the handshake age an honest liveness signal.
        peer=$($wg show "$iface" peers 2>/dev/null | /usr/bin/head -1)
        [ -n "$peer" ] && $wg set "$iface" peer "$peer" persistent-keepalive 25 2>/dev/null

        shook=$($wg show "$iface" latest-handshakes 2>/dev/null | /usr/bin/awk '{ print $2 }' | /usr/bin/head -1)
        [ -n "$shook" ] && [ "$shook" -gt 0 ] || return 1
        [ $(( $(/bin/date +%s) - shook )) -lt ${toString staleHandshake} ]
      }

      # The Proton app's NetworkExtension tunnel shows up in scutil with its
      # state; any Proton entry that is connected, or trying to, means the app
      # owns the routes.
      protonAppActive() {
        /usr/sbin/scutil --nc list 2>/dev/null \
          | /usr/bin/grep -i proton \
          | /usr/bin/grep -Eq '\((Connected|Connecting)\)'
      }

      # Booting the daemon out drops the rules with it — the escape hatch if any
      # of this misbehaves. A crash leaves them in place; KeepAlive restarts us.
      trap '/sbin/pfctl -a ${anchor} -F rules 2>/dev/null; /bin/rm -f ${loadedRules}; exit 0' TERM INT

      /sbin/pfctl -E >/dev/null 2>&1
      /sbin/pfctl -sA 2>/dev/null | /usr/bin/grep -q '^  ${anchor}$' \
        || /sbin/pfctl -f ${pfRuleset} 2>/dev/null

      while :; do
        interval=10

        if [ -f ${bypassFile} ]; then
          if [ $(( $(/bin/date +%s) - $(/usr/bin/stat -f %m ${bypassFile}) )) -lt ${toString bypassSeconds} ]; then
            applyRules < /dev/null
            /bin/sleep 10
            continue
          fi
          /bin/rm -f ${bypassFile}
        fi

        # The app's tunnel and this one cannot route side by side — both claim
        # the default route, and the extension pins its transport to the
        # physical link, so nesting them is out as well. Yield while the app is
        # up or trying: rules aside so its handshake is not blocked, baseline
        # down so the routes are its alone. Leak protection is the app's own
        # kill switch for as long as it holds the tunnel.
        if protonAppActive; then
          applyRules < /dev/null
          if [ -s ${nameFile} ]; then
            $wgQuick down ${tunnel} >/dev/null 2>&1
          fi
          /bin/sleep 10
          continue
        fi

        if [ ! -f ${configFile} ]; then
          # No profile to connect with. Blocking here would leave a machine with
          # no network and no way to fetch the profile that fixes it.
          applyRules < /dev/null
          /bin/sleep 30
          continue
        fi

        if tunnelUp; then
          $wg show "$iface" endpoints 2>/dev/null \
            | /usr/bin/awk '{ print $2 }' | /usr/bin/head -1 > ${endpointFile}
          killSwitch "$iface"
        else
          killSwitch ""
          $wgQuick down ${tunnel} >/dev/null 2>&1
          $wgQuick up ${tunnel} >/dev/null 2>&1 || interval=30
        fi

        /bin/sleep "$interval"
      done
    '';

    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/var/log/vpn-tunnel.err";
    };
  };

  # Re-applies what a network change is able to move: the resolver DHCP hands
  # each interface, and stealth mode. /var/run/resolv.conf is rewritten on every
  # network configuration change, which makes it the trigger; the interval is
  # the safety net for a change that does not touch it.
  launchd.daemons.network-hardening = {
    script = ''
      export PATH=/usr/bin:/bin:/usr/sbin:/sbin

      /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on >/dev/null 2>&1

      # Only worth pinning when something is listening: nextdns is installed per
      # machine with an account-specific config ID, and pointing at a resolver
      # that is not there would take DNS down altogether.
      /usr/sbin/netstat -an -p udp 2>/dev/null | /usr/bin/grep -q '127.0.0.1.53 ' || exit 0

      /usr/sbin/networksetup -listallnetworkservices 2>/dev/null | /usr/bin/tail -n +2 |
        while read -r service; do
          case "$service" in
            \**) continue ;;
          esac

          /usr/sbin/networksetup -getdnsservers "$service" 2>/dev/null \
            | /usr/bin/grep -qx '127.0.0.1' && continue
          /usr/sbin/networksetup -setdnsservers "$service" 127.0.0.1 >/dev/null 2>&1
        done
    '';

    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 300;
      WatchPaths = [ "/var/run/resolv.conf" ];
      StandardErrorPath = "/var/log/network-hardening.err";
    };
  };
}
