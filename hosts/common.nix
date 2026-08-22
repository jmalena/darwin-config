{ ... }:

# Shared by every host. Identity — hostname, primary user — lives in the
# per-host file; everything below is machine-independent.
{
  imports = [
    ../modules/nix.nix
    ../modules/macos.nix
    ../modules/security.nix
    ../modules/vpn.nix
    ../modules/packages.nix
    ../modules/homebrew.nix
    ../modules/home.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
