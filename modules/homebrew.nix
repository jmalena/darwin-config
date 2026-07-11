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

    brews = [ ];

    casks = [
      "chatgpt"
      "claude-code"
      "docker-desktop"
      "emacs-app"
      "figma"
      "google-chrome"
      "mongodb-compass"
      "spotify"
    ];
  };
}
