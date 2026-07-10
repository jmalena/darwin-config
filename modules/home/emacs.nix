{ pkgs, config, ... }:

{
  home.packages = [
    pkgs.emacs-nox
    pkgs.rust-analyzer # lsp server for rust-mode syntax highlighting
    pkgs.svelte-language-server # lsp server for svelte-mode
  ];

  # init.el is vendored from github.com/jmalena/init.el and lives in this repo.
  # An out-of-store symlink keeps it live-editable (no rebuild to iterate) while
  # straight.el writes its packages into ~/.config/emacs/straight/ alongside it.
  xdg.configFile."emacs/init.el".source =
    config.lib.file.mkOutOfStoreSymlink
      "/Users/aleph/Projects/darwin-config/modules/home/emacs/init.el";

  # Run Emacs as a login daemon so `emacsclient` (our EDITOR) is instant.
  launchd.agents.emacs = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.emacs-nox}/bin/emacs" "--daemon" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
