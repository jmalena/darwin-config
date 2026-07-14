{ ... }:

{
  nix-homebrew = {
    enable = true;
    user = "aleph";
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
