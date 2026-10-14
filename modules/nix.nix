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
    max-jobs = "auto";

    # Deliberately not @admin: a trusted user is effectively passwordless root.
    trusted-users = [ "root" ];

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
