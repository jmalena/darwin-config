{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
      extended = true;
    };

    shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/Desktop/Projekty/darwin-config#eigen";
    };

    dirHashes = {
      proj = "$HOME/Desktop/Projekty";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables = {
    EDITOR = "emacsclient -t -a emacs";
    VISUAL = "emacsclient -t -a emacs";
  };
}
