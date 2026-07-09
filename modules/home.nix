{ ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  home-manager.users.aleph = {
    imports = [
      ./home/dev.nix
      ./home/git.nix
      ./home/shell.nix
      ./home/emacs.nix
      ./home/lock.nix
    ];

    home.stateVersion = "25.05";
  };
}
