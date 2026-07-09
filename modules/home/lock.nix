{ pkgs, ... }:

let
  # Lock straight to the login window (Touch ID / password). macOS 26 gates the
  # screen-lock grace period behind sysadminctl auth, so it can't be set
  # declaratively; locking on sleep forces re-auth on every lid close instead.
  lockScreen = pkgs.writeShellScript "lock-screen" ''
    /usr/bin/python3 -c 'import ctypes; ctypes.CDLL("/System/Library/PrivateFrameworks/login.framework/login").SACLockScreenImmediate()'
  '';
in
{
  # sleepwatcher fires the lock the moment the system sleeps (lid close), so
  # reopening lands on the Touch ID / password screen.
  launchd.agents.sleepwatcher = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.sleepwatcher}/bin/sleepwatcher"
        "--sleep" "${lockScreen}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
