{ ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  nix.optimise.automatic = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    keep-outputs = true;
    keep-derivations = true;

    # A trusted user can push arbitrary paths through the root nix daemon, so
    # @admin here amounts to passwordless root for any process running as an
    # admin user. Root builds (sudo darwin-rebuild) are unaffected.
    trusted-users = [ "root" ];
    require-sigs = true;
    max-jobs = "auto";

    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}
