{ pkgs, ... }:

# Global editor-tooling layer: version-tolerant LSPs, formatters, and linters
# that GUI Emacs must find on PATH. Language runtimes, haskell-language-server,
# and rust-analyzer intentionally stay per-project (flake devShells + direnv).
{
  home.packages = with pkgs; [
    # Nix
    nixd
    nixfmt
    statix
    deadnix

    # Search (ag — required by init.el's helm-ag; silver-searcher was removed
    # from nixpkgs, silver-searcher-ng is the maintained PCRE2 fork)
    silver-searcher-ng

    # Shell
    shellcheck
    shfmt

    # JS / TS / Deno
    typescript-language-server
    typescript
    deno

    # Python
    uv
    ruff
    pyright

    # Haskell (HLS stays per-project, matching each project's GHC)
    hlint
    fourmolu

    # Dhall
    dhall
    dhall-lsp-server

    # C / C++
    clang-tools

    # Idris2
    idris2
    idris2Packages.idris2Lsp

    # Config-file LSPs
    taplo
    yaml-language-server
    vscode-langservers-extracted # JSON (vscode-json-language-server) + CSS/HTML
    marksman

    # YubiKey
    yubikey-manager

    # Nix dev UX
    devenv
    nvd
    nix-output-monitor
  ];
}
