{ pkgs, ... }:

let
  # Lock straight to the login window (Touch ID / password). macOS 26 gates the
  # screen-lock grace period behind sysadminctl auth, so it can't be set
  # declaratively; locking on sleep forces re-auth on every lid close instead.
  # Pinned to a store python rather than /usr/bin/python3: the system interpreter
  # ships with the Command Line Tools and an OS update removing it would silently
  # break locking.
  lockScreen = pkgs.writeShellScript "lock-screen" ''
    ${pkgs.python3}/bin/python3 -c 'import ctypes; ctypes.CDLL("/System/Library/PrivateFrameworks/login.framework/login").SACLockScreenImmediate()'
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
