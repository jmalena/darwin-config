{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Report the working directory to Apple Terminal so new tabs/windows
    # (Cmd+T / Cmd+N) open in the current folder.
    initContent = ''
      if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
        autoload -Uz add-zsh-hook
        _osc7_cwd() {
          local url="file://$HOST" i ch
          for ((i = 1; i <= ''${#PWD}; i++)); do
            ch="$PWD[i]"
            case "$ch" in
              [a-zA-Z0-9/._~-]) url+="$ch" ;;
              *) url+=$(printf '%%%02X' "'$ch") ;;
            esac
          done
          printf '\e]7;%s\a' "$url"
        }
        add-zsh-hook chpwd _osc7_cwd
        _osc7_cwd
      fi
    '';

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
      extended = true;
    };

    shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/Projects/darwin-config#eigen";
    };

    dirHashes = {
      proj = "$HOME/Projects";
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
