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

    brews = [ "mas" ];

    casks = [
      "chatgpt"
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

    masApps = {
      "Proton Authenticator" = 6741758667;
    };
  };
}
