# CLAUDE.md

Guidance for working in this nix-darwin configuration.

## Principles

- Add comments only when really necessary; let the code read for itself.
- Keep it simple and readable — prefer clear options over clever expressions.

## Hosts

One module set, identical for every host. The `hosts` table in `flake.nix` maps
hostname to primary user and is the only place a username appears; `mkHost`
turns each entry into a `darwinConfigurations` output. Every module derives
paths from `config.system.primaryUser` (system scope) or
`config.home.homeDirectory` (Home Manager scope).

| Host | Primary user |
| --- | --- |
| `eigen` | `aleph` |
| `zweigen` | `bet` |

Adding a host or account is one line in that table — nothing else changes.

## Layout

- `flake.nix` — inputs, the `hosts` table, and the outputs built from it.
- `hosts/common.nix` — shared imports, platform, state version.
- `modules/nix.nix` — nix settings: gc, optimise, caches, experimental features.
- `modules/macos.nix` — macOS defaults, fonts, dock pinning, Spotlight scope, wallpaper, Chrome policy.
- `modules/security.nix` — Touch ID, firewall, login window, screen lock, clamshell logout, AirDrop, Continuity, sharing services.
- `modules/packages.nix` — system CLI packages.
- `modules/homebrew.nix` — nix-homebrew and declarative casks.
- `modules/home.nix` — Home Manager aggregator; imports `modules/home/*`.
- `modules/home/{dev,git,shell,emacs}.nix` — user env: tooling, git, shell, Emacs.
- `modules/home/store-sync.nix` — mirrors the STORE drive to STORE_BAK (Cryptomator vault ciphertext).
- `modules/home/security.nix` — ByHost prefs (screen-saver idle, AirPlay Receiver) that need `-currentHost`.
- `modules/home/emacs/init.el` — Emacs config, edited here (symlinked to `~/.config/emacs`).

## Commands

- Apply:  `sudo darwin-rebuild switch --flake .` (picks the output matching this hostname)
- Check:  `nix build .#darwinConfigurations.<host>.system`
- Update: `nix flake update`

## Conventions

- Prefer declarative nix-darwin / Home Manager options over shell scripts.
- GUI apps as Homebrew `casks`; CLI tools as Nix packages.
- Never hardcode a username or `/Users/<name>` path anywhere but the `hosts`
  table in `flake.nix` — derive it from `config.system.primaryUser` or
  `config.home.homeDirectory` instead.
