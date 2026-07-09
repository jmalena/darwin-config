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
      "claude-code"
      "docker-desktop"
      "emacs-app"
      "figma"
      "ghostty"
      "google-chrome"
      "spotify"
    ];
  };
}
