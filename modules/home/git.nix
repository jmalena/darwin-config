{ pkgs, config, ... }:

let
  # launchd's ssh-agent can't drive ed25519-sk keys, so sign without it.
  signer = pkgs.writeShellScript "git-ssh-keygen" ''
    exec ${pkgs.coreutils}/bin/env -u SSH_AUTH_SOCK ${pkgs.openssh}/bin/ssh-keygen "$@"
  '';
in
{
  programs.git = {
    enable = true;

    settings = {
      user.name = "Jonáš Malena";
      user.email = "jonas.malena@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      # macOS's /usr/bin/ssh has no FIDO support; nixpkgs openssh does.
      core.sshCommand = "${pkgs.openssh}/bin/ssh";
      url."git@github.com:".pushInsteadOf = "https://github.com/";

      # Commits and tags are signed with the YubiKey (touch to sign).
      gpg.format = "ssh";
      gpg.ssh.program = "${signer}";
      user.signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk.pub";
      commit.gpgSign = true;
      tag.gpgSign = true;

      # delta is the pager, difftastic the difftool (`git dft`). Home Manager
      # refuses to enable both integrations, so the difftool is wired here.
      diff.tool = "difftastic";
      difftool.prompt = false;
      difftool.difftastic.cmd = ''${pkgs.difftastic}/bin/difft "$LOCAL" "$REMOTE"'';

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
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
    };
  };

  programs.difftastic.enable = true;
}
