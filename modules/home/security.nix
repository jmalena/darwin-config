{ ... }:

# User-scope preferences. nix-darwin's CustomUserPreferences writes with plain
# `defaults write`, so it cannot reach the -currentHost domains below.
{
  targets.darwin.defaults = {
    # AirPlay Receiver listens on *:5000 and *:7000 LAN-wide and is unrelated to
    # AirDrop. macOS 26 moved the gate here from com.apple.controlcenter's
    # AirplayRecieverEnabled, which is now inert — ControlCenter re-binds both
    # ports regardless of it. This key is what System Settings > General >
    # AirDrop & Handoff actually writes; it closes the sockets live, no restart.
    # Undocumented by Apple: the com.apple.airplay.security domain is published
    # only as a tvOS MDM payload. Verify with:
    #   lsof -iTCP -sTCP:LISTEN -P -n | grep -E ':5000|:7000'
    "com.apple.airplay.security".ReceiverDisabled = true;
  };

  targets.darwin.currentHostDefaults = {
    # Start the screen saver after 10 minutes. The unlock grace period is not
    # settable declaratively on macOS 26 — run `sysadminctl -screenLock immediate`.
    "com.apple.screensaver".idleTime = 600;
  };
}
