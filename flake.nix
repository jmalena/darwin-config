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

  outputs = inputs@{ nix-darwin, home-manager, nix-homebrew, ... }:
    let
      # hostname → primary user. This is the only place either name appears:
      # every module derives its paths from the primary user or the home
      # directory, so a new machine or account is one line here and nothing else.
      hosts = {
        eigen = "aleph";
        zweigen = "bet";
      };

      mkHost = hostName: user: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/common.nix
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          {
            networking.hostName = hostName;

            system.primaryUser = user;

            users.users.${user} = {
              name = user;
              home = "/Users/${user}";
            };
          }
        ];
      };
    in
    {
      darwinConfigurations = builtins.mapAttrs mkHost hosts;
    };
}
