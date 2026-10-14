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
      "python3"
    ];

    casks = [
      "claude"
      "claude-code"
      "docker-desktop"
      "emacs-app"
      "figma"
      "google-chrome"
      "mongodb-compass"
      "proton-mail"
      "proton-pass"
      "protonvpn"
      "spotify"

      # Objective-See security tools
      "blockblock" # alerts when anything installs a persistence item
      "do-not-disturb" # alerts when the lid is opened while away
      "lulu" # outbound firewall
      "oversight" # alerts on mic and camera access
    ];
  };
}
