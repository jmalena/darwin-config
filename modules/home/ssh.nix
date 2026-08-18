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
