{ pkgs, config, ... }:

{
  # nixpkgs openssh, built with security-key support — macOS's /usr/bin/ssh has
  # no FIDO provider and silently skips sk-* keys.
  programs.ssh = {
    enable = true;
    package = pkgs.openssh;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "no";
        ServerAliveInterval = 60;

        # macOS points SSH_AUTH_SOCK at launchd's agent, which cannot drive
        # ed25519-sk and refuses every request. ssh prefers an agent copy of a
        # key over the file, so one stray ssh-add is enough to break auth until
        # the key is evicted again; ignoring the agent keeps it touch-only.
        IdentityAgent = "none";
      };

      # Authenticate to GitHub with the YubiKey (touch-to-push).
      "github.com" = {
        User = "git";
        IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519_sk";
        IdentitiesOnly = true;
      };
    };
  };
}
