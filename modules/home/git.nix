{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name = "Jonáš Malena";
      user.email = "jonas.malena@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      # Use nixpkgs ssh (built --with-security-key-builtin) for git remotes, so
      # the YubiKey FIDO2 key authenticates — /usr/bin/ssh has no FIDO provider.
      core.sshCommand = "${pkgs.openssh}/bin/ssh";

      # YubiKey 5 NFC — FIDO2 SSH signing (touch-to-sign). macOS's
      # /usr/bin/ssh-keygen has no FIDO provider, so sign with nixpkgs openssh.
      gpg.format = "ssh";
      gpg.ssh.program = "${pkgs.openssh}/bin/ssh-keygen";
      user.signingKey = "/Users/aleph/.ssh/id_ed25519_sk.pub";
      commit.gpgSign = true;
      tag.gpgSign = true;

      alias = {
        s = "status -sb";
        lg = "log --oneline --graph --decorate";
        co = "checkout";
        dft = "difftool";
      };
    };

    ignores = [
      ".direnv"
      "result"
      "result-*"
      "target/"
      "node_modules"
      ".venv"
      "dist-newstyle"
      ".DS_Store"
      "*.hi"
      "*.o"
    ];

    maintenance.enable = true;
  };

  # delta as the git pager; difftastic wired up as `git difftool`.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
    };
  };

  programs.difftastic = {
    enable = true;
    git.mode = "difftool";
  };
}
