{ config, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  home-manager.users.${config.system.primaryUser} = {
    imports = [
      ./home/dev.nix
      ./home/git.nix
      ./home/shell.nix
      ./home/ssh.nix
      ./home/emacs.nix
      ./home/lock.nix
      ./home/security.nix
    ];

    home.stateVersion = "25.05";
  };
}
