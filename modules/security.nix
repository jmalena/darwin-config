{ config, lib, pkgs, ... }:

let
  # Application firewall entries to revoke. Interpreters accept inbound for any
  # script run under them; the daemons belong to sharing services kept off.
  firewallRevoke = [
    "/usr/bin/python3"
    "/usr/bin/ruby"
    "/usr/sbin/smbd"
    "/usr/libexec/sshd-keygen-wrapper"
    "/usr/sbin/cupsd"
    "/Applications/Spotify.app"
    "/Applications/Google Chrome.app"
  ];

  # Sharing daemons held off at the launchd level, independent of the Sharing
  # pane. AppleFileServer and AEServer no longer ship on macOS 26.
  byHost = "/Users/${config.system.primaryUser}/Library/Preferences/ByHost";

  sharingDaemons = [
    "com.apple.screensharing"
    "com.apple.smbd"
    "com.apple.netbiosd"
    "com.apple.eppc"
  ];
in
{
  security.pam.services.sudo_local.touchIdAuth = true;

  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;

    # Apple-signed software stays auto-allowed because sharingd — which implements
    # AirDrop — is Apple-signed. Third-party signed apps must be listed explicitly;
    # leaving this on is what let a stray python server accept LAN traffic.
    allowSigned = true;
    allowSignedApp = false;

    # Blocking all incoming disables every sharing service, AirDrop included.
    blockAllIncoming = false;
  };

  networking.wakeOnLan.enable = false;

  system.defaults = {
    loginwindow = {
      SHOWFULLNAME = true;
      GuestEnabled = false;
      DisableConsoleAccess = true;
      ShutDownDisabled = true;
      RestartDisabled = true;
      SleepDisabled = true;
    };

    # macOS 26 reads the unlock grace period from an authenticated store rather
    # than these keys, so `sysadminctl -screenLock immediate` is the control that
    # actually applies. Declaring them still pins the plist against drift.
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    CustomUserPreferences = {
      "com.apple.sharingd".DiscoverableMode = "Contacts Only";

      # Handoff and Universal Clipboard. Separate from AirDrop.
      "com.apple.coreservices.useractivityd" = {
        ActivityAdvertisingAllowed = false;
        ActivityReceivingAllowed = false;
      };

      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
        forceLimitAdTracking = true;
      };

      "com.apple.SubmitDiagInfo".AutoSubmit = false;
    };
  };

  # The unified log holds roughly 20 days before rolling over. Archive a day at
  # a time so evidence survives long enough to investigate something noticed
  # late — the backup/temp account sessions were only reconstructable because
  # records happened to still be in range. Refuses to run when the disk is
  # tight; this must never be the thing that fills it.
  launchd.daemons.security-log-archive = {
    script = ''
      dir=/var/log/security-archive

      free=$(/bin/df -g / | /usr/bin/awk 'NR==2 { print $4 }')
      if [ "''${free:-0}" -lt 20 ]; then
        exit 0
      fi

      /bin/mkdir -p "$dir"
      /usr/bin/log collect --last 1d --output "$dir/$(/bin/date +%Y-%m-%d).logarchive" || true
      /usr/bin/find "$dir" -maxdepth 1 -name '*.logarchive' -mtime +90 -exec /bin/rm -rf {} + || true
    '';

    serviceConfig = {
      StartCalendarInterval = [ { Hour = 4; Minute = 30; } ];
      RunAtLoad = false;
      StandardErrorPath = "/var/log/security-archive.err";
    };
  };

  # The login window runs as root and places itself on whichever display root's
  # saved arrangement calls main. Root has no such arrangement, so it falls back
  # to the built-in panel and the external screen stays dark. Mirror the primary
  # user's arrangement into root's ByHost domain whenever it changes, and the
  # login window lands on the same main display the session uses. macOS draws it
  # on one screen only; there is no setting that puts it on both.
  launchd.daemons.loginwindow-display-sync = {
    script = ''
      domain=com.apple.windowserver.displays
      uuid=$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice \
        | /usr/bin/awk -F'"' '/IOPlatformUUID/ { print $4 }')
      src=${byHost}/$domain.$uuid.plist

      [ -f "$src" ] || exit 0

      # import rather than a copy: it goes through cfprefsd, so root's cached
      # copy of the domain cannot overwrite the file afterwards.
      /usr/bin/defaults -currentHost import "$domain" "$src"
    '';

    serviceConfig = {
      RunAtLoad = true;
      WatchPaths = [ byHost ];
      StandardErrorPath = "/var/log/loginwindow-display-sync.err";
    };
  };

  # Closing the lid with an external display attached leaves the machine awake
  # in clamshell mode: the session stays unlocked behind a screen nobody is
  # looking at. End it the moment that happens. A lid close with nothing else
  # attached only sleeps, which the immediate screen lock already covers.
  launchd.daemons.clamshell-logout = {
    script = ''
      lidClosed() {
        /usr/sbin/ioreg -r -k AppleClamshellState -d 1 \
          | /usr/bin/grep -q '"AppleClamshellState" = Yes'
      }

      # The built-in panel is the only display that reports a connection type,
      # so anything else the window server lists is external.
      externalDisplay() {
        count=$(/usr/sbin/system_profiler -json SPDisplaysDataType 2>/dev/null |
          ${pkgs.jq}/bin/jq '[.SPDisplaysDataType[]?.spdisplays_ndrvs[]?
            | select(.spdisplays_connection_type != "spdisplays_internal")]
            | length' 2>/dev/null)
        [ "''${count:-0}" -gt 0 ]
      }

      while :; do
        interval=1

        if lidClosed; then
          if externalDisplay; then
            uid=$(/usr/bin/stat -f %u /dev/console)
            # Below 501 is the login window itself: no session left to end.
            if [ "''${uid:-0}" -ge 501 ]; then
              # bootout rather than an AppleScript logout: no confirmation
              # dialog, and no app can veto it by holding unsaved changes.
              /bin/launchctl bootout "gui/$uid"
            fi
          else
            # On its way to sleep. Back off instead of asking the display list
            # once a second, while still catching a display attached later.
            interval=10
          fi
        fi

        /bin/sleep "$interval"
      done
    '';

    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/var/log/clamshell-logout.err";
    };
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    fw=/usr/libexec/ApplicationFirewall/socketfilterfw

    # sharingd implements AirDrop. It is Apple-signed, so allowSigned already
    # covers it; pinning it explicitly keeps AirDrop working if allowSigned is
    # ever turned off.
    "$fw" --add /usr/libexec/sharingd >/dev/null 2>&1 || true
    "$fw" --unblockapp /usr/libexec/sharingd >/dev/null 2>&1 || true

    ${lib.concatMapStringsSep "\n    " (
      app: ''"$fw" --remove ${lib.escapeShellArg app} >/dev/null 2>&1 || true''
    ) firewallRevoke}

    ${lib.concatMapStringsSep "\n    " (
      label: ''launchctl disable "system/${label}" 2>/dev/null || true''
    ) sharingDaemons}
  '';
}
