{ pkgs, config, ... }:

{
  programs.ssh = {
    enable = true;
    # macOS's /usr/bin/ssh has no FIDO support; nixpkgs openssh does.
    package = pkgs.openssh;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ServerAliveInterval = 60;
        # launchd's ssh-agent can't drive ed25519-sk keys and would shadow the key file.
        IdentityAgent = "none";
      };

      "github.com" = {
        User = "git";
        IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519_sk";
        IdentitiesOnly = true;
      };
    };
  };
}
