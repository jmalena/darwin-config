{
  imports = [
    ./nix.nix
    ./macos.nix
    ./packages.nix
    ./homebrew.nix
    ./home.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
}
