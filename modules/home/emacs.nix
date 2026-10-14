{ pkgs, config, ... }:

let
  # Out-of-store symlinks into the checkout: edits apply without a rebuild, and
  # `M-x straight-freeze-versions` writes the lockfile back to the repo.
  link = file: config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/Projects/darwin-config/modules/home/emacs/${file}";
in
{
  home.packages = [ pkgs.emacs-nox ];

  xdg.configFile."emacs/init.el".source = link "init.el";
  xdg.configFile."emacs/straight/versions/default.el".source = link "straight-versions.el";

  # Login daemon for `emacsclient`. --fg-daemon stays in the foreground so
  # launchd's KeepAlive supervises it instead of respawning it.
  launchd.agents.emacs = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.emacs-nox}/bin/emacs" "--fg-daemon" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
