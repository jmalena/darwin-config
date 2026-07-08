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

    # `ls`/`ll`/`la`/`lt` are provided by the eza module's zsh integration.
    shellAliases = {
      cat = "bat";
      rebuild = "sudo darwin-rebuild switch --flake ~/Desktop/Projekty/darwin-config#eigen";
    };

    dirHashes = {
      proj = "$HOME/Desktop/Projekty";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      direnv.disabled = false;
      nix_shell.disabled = false;
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    fileWidget.command = "fd --type f --hidden --exclude .git";
    changeDirWidget.command = "fd --type d --hidden --exclude .git";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
    enableZshIntegration = true;
  };

  home.sessionVariables = {
    EDITOR = "emacsclient -c -a emacs";
    VISUAL = "emacsclient -c -a emacs";
  };
}
