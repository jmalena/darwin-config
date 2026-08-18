{ config, ... }:

{
  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    enableRosetta = true;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    brews = [
      "mas"
      "python3"

      # DNS-over-HTTPS resolver, run as a LaunchDaemon on 127.0.0.1. Wired up
      # with `sudo nextdns install -config <id>` — a NextDNS config ID is
      # tied to the user's account/blocklists and isn't declarable here.
      "nextdns"
    ];

    casks = [
      "claude"
      "claude-code"
      "cryptomator"
      "emacs-app"
      "figma"

      # Cryptomator's mount driver. FUSE-T runs entirely in userspace, so eigen keeps
      # its Full Security boot policy — macFUSE would need a Recovery trip to allow
      # kernel extensions. Upstream's recommendation on Apple Silicon.
      "fuse-t"

      "google-chrome"
      "mongodb-compass"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      "spotify"

      # Objective-See monitoring. These ship system extensions that only load from
      # /Applications, so they come from Homebrew rather than nixpkgs.
      "blockblock" # alerts when anything installs a persistence item
      "do-not-disturb" # alerts when the lid is opened while away
      "lulu" # outbound firewall
      "oversight" # alerts on mic and camera access
    ];

    # These Proton apps aren't managed here: `mas` can't install them from the CLI
    # (Apple removed first-time "Get", so it only re-downloads apps already in your
    # purchase history; Proton Authenticator is also an iOS app on Apple Silicon,
    # not a native Mac App Store app). Install each once by hand from the App Store:
    #   Proton Pass for Safari  https://apps.apple.com/app/id6502835663
    #   Proton Authenticator    https://apps.apple.com/app/id6741758667
    masApps = { };
  };
}
