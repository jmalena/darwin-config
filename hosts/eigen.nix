{ ... }:

{
  imports = [
    ../modules/nix.nix
    ../modules/macos.nix
    ../modules/packages.nix
    ../modules/homebrew.nix
    ../modules/home.nix
  ];

  networking.hostName = "eigen";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "aleph";
  system.stateVersion = 6;

  users.users.aleph = {
    name = "aleph";
    home = "/Users/aleph";
  };
}
