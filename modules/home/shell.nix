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
      # A leading space keeps a command out of history.
      ignoreSpace = true;

      # Never write credential-like commands to disk.
      ignorePatterns = [
        "*-password*"
        "*-token*"
        "*_TOKEN=*"
        "*_SECRET=*"
        "*_KEY=*"
        "*API_KEY*"
        "*PASSWORD*"
        "security *"
        "sysadminctl *"
        "*fdesetup*"
      ];
    };

    dirHashes.proj = "$HOME/Projects";
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
