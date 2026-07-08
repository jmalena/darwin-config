# CLAUDE.md

Guidance for working in this nix-darwin configuration.

## Principles

- Add comments only when really necessary; let the code read for itself.
- Keep it simple and readable — prefer clear options over clever expressions.

## Layout

- `flake.nix` — inputs and the `eigen` system output.
- `hosts/eigen.nix` — host identity + module imports.
- `modules/nix.nix` — nix settings: gc, optimise, caches, experimental features.
- `modules/macos.nix` — macOS defaults, fonts, Touch ID, firewall, dock pinning, Spotlight scope, wallpaper.
- `modules/packages.nix` — system CLI packages.
- `modules/homebrew.nix` — nix-homebrew and declarative casks.
- `modules/home.nix` — Home Manager aggregator; imports `modules/home/*`.
- `modules/home/{dev,git,shell,emacs}.nix` — user env: tooling, git, shell, Emacs.
- `modules/home/emacs/init.el` — Emacs config, edited here (symlinked to `~/.config/emacs`).

## Commands

- Apply:  `sudo darwin-rebuild switch --flake .#eigen`
- Check:  `nix build .#darwinConfigurations.eigen.system`
- Update: `nix flake update`

## Conventions

- Prefer declarative nix-darwin / Home Manager options over shell scripts.
- GUI apps as Homebrew `casks`; CLI tools as Nix packages.
