{
  description = "nix-darwin configuration, one module set shared by every host";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { nix-darwin, home-manager, nix-homebrew, ... }:
    let
      # hostname → primary user. The only place a username appears.
      hosts = {
        eigen = "aleph";
        zweigen = "bet";
      };

      mkHost = hostName: user: nix-darwin.lib.darwinSystem {
        modules = [
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          ./modules
          {
            networking.hostName = hostName;
            system.primaryUser = user;
            users.users.${user}.home = "/Users/${user}";
          }
        ];
      };
    in
    {
      darwinConfigurations = builtins.mapAttrs mkHost hosts;
    };
}
