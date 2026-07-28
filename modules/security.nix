{ lib, ... }:

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
