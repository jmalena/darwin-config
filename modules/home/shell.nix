{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Report the working directory to Apple Terminal so new tabs/windows
    # (Cmd+T / Cmd+N) open in the current folder.
    initContent = ''
      # pinentry prompts on the controlling terminal, so gpg signing on the
      # YubiKey fails with "Inappropriate ioctl for device" without this. Per
      # shell rather than a session variable, since every terminal has its own.
      export GPG_TTY=$TTY

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

      # Overwrite a file or folder with zeros, then delete it. rm -P is a no-op
      # on modern macOS, and on APFS the zeros land in freshly allocated blocks,
      # so this blanks the contents rather than making the originals
      # unrecoverable — for that, FileVault plus an ordinary delete.
      purge() {
        emulate -L zsh
        zmodload -F zsh/stat b:zstat

        (( $# )) || { print -u2 'usage: purge <file|folder>...'; return 2 }

        local target
        for target in "$@"; do
          [[ -e $target || -L $target ]] || {
            print -u2 "purge: $target: no such file or directory"
            return 1
          }
        done

        print -n "purge $# item(s) beyond recall? [y/N] "
        local reply
        read -r reply || return 1
        [[ $reply == [yY]* ]] || return 1

        local f
        local -a files st
        for target in "$@"; do
          if [[ -L $target ]]; then
            files=()
          elif [[ -d $target ]]; then
            files=($target/**/*(D.N))
          else
            files=($target)
          fi

          for f in $files; do
            zstat -A st +size -- $f
            head -c $st[1] /dev/zero | dd of=$f conv=notrunc status=none
          done

          rm -rf -- $target
        done
      }
    '';

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
      extended = true;

      # Prefix a command with a space to keep it out of the history entirely.
      ignoreSpace = true;

      # Credential-shaped commands are never written to disk. Single-dash forms
      # matter too — sysadminctl takes `-password`, not `--password`.
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

    shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/Projects/darwin-config";
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
