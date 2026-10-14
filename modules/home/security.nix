# -currentHost preferences, which nix-darwin's CustomUserPreferences can't write.
{
  targets.darwin.currentHostDefaults = {
    # Screen saver after 10 minutes. For the unlock grace period (not settable
    # declaratively on macOS 26), run `sysadminctl -screenLock immediate` once.
    "com.apple.screensaver".idleTime = 600;
  };
}
