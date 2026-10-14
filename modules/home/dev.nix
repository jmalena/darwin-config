{ pkgs, ... }:

# LSP servers, formatters and linters Emacs finds on PATH.
# haskell-language-server stays per-project to match each project's GHC.
{
  home.packages = with pkgs; [
    # Nix
    nixd
    nixfmt
    statix
    deadnix

    # ag, for Emacs' ag-project
    silver-searcher-ng

    # Shell
    shellcheck
    shfmt

    # JS / TS / Deno / Svelte
    typescript-language-server
    typescript
    deno
    svelte-language-server

    # Python
    uv
    ruff
    pyright

    # Haskell
    hlint
    fourmolu

    # Dhall
    dhall
    dhall-lsp-server

    # C / C++
    clang-tools

    # Rust
    rust-analyzer

    # Idris2
    idris2
    idris2Packages.idris2Lsp

    # Lean 4 (its LSP is `lake serve`)
    lean4

    # Config files
    taplo
    yaml-language-server
    vscode-langservers-extracted
    marksman

    # YubiKey
    yubikey-manager

    # Nix workflow
    devenv
    nvd
    nix-output-monitor
  ];
}
