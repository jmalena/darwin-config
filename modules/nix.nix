{ config, lib, pkgs, ... }:

let
  # Login Items & Extensions names a background item after its executable, and
  # nix-darwin starts its daemons as `/bin/sh -c "wait4path …"`, so each shows
  # up as "sh". Start them through a launcher named after the daemon instead.
  # It lives outside /nix: launchd runs these before the store volume mounts.
  launcherDir = "/usr/local/libexec/nix-darwin";
  launcher = pkgs.writeScript "launcher" ''
    #!/bin/sh
    exec /bin/sh "$@"
  '';
  # The ones nix-darwin can't run without. Garbage collection and store
  # optimisation run from install.sh instead of adding more background items.
  daemons = [ "activate-system" "nix-daemon" ];
in
{
  nixpkgs.config.allowUnfree = true;

  launchd.daemons = lib.genAttrs daemons (name: {
    serviceConfig.ProgramArguments = lib.mkForce [
      "${launcherDir}/${name}"
      "-c"
      "/bin/wait4path /nix/store && exec ${config.launchd.daemons.${name}.command}"
    ];
  });

  # Before the launchd step, which (re)loads the daemons.
  system.activationScripts.preActivation.text = ''
    mkdir -p ${launcherDir}
    ${lib.concatMapStrings (name: "install -m 755 ${launcher} ${launcherDir}/${name}\n") daemons}
  '';

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
