# CLAUDE.md

Guidance for working in this nix-darwin configuration.

## Principles

- Add comments only when really necessary; let the code read for itself.
- Keep it simple and readable — prefer clear options over clever expressions.

## Hosts

Two machines, one shared module set. A host file carries only identity —
hostname and primary user; every module derives paths from
`config.system.primaryUser` (system scope) or `config.home.homeDirectory`
(Home Manager scope), so nothing hardcodes a username.

| Host | Primary user |
| --- | --- |
| `eigen` | `aleph` |
| `zweigen` | `bet` |

## Layout

- `flake.nix` — inputs and the `eigen` / `zweigen` system outputs.
- `hosts/common.nix` — shared imports, platform, state version.
- `hosts/{eigen,zweigen}.nix` — host identity: hostname, primary user.
- `modules/nix.nix` — nix settings: gc, optimise, caches, experimental features.
- `modules/macos.nix` — macOS defaults, fonts, dock pinning, Spotlight scope, wallpaper, Chrome policy.
- `modules/security.nix` — Touch ID, firewall, login window, screen lock, AirDrop, Continuity, sharing services.
- `modules/packages.nix` — system CLI packages.
- `modules/homebrew.nix` — nix-homebrew and declarative casks.
- `modules/home.nix` — Home Manager aggregator; imports `modules/home/*`.
- `modules/home/{dev,git,shell,emacs}.nix` — user env: tooling, git, shell, Emacs.
- `modules/home/security.nix` — ByHost prefs (screen-saver idle, AirPlay Receiver) that need `-currentHost`.
- `modules/home/emacs/init.el` — Emacs config, edited here (symlinked to `~/.config/emacs`).

## Commands

- Apply:  `sudo darwin-rebuild switch --flake .` (picks the output matching this hostname)
- Check:  `nix build .#darwinConfigurations.<host>.system`
- Update: `nix flake update`

## Conventions

- Prefer declarative nix-darwin / Home Manager options over shell scripts.
- GUI apps as Homebrew `casks`; CLI tools as Nix packages.
- Never hardcode a username or `/Users/<name>` path in `modules/` — it belongs
  in `hosts/`, or derive it from the primary user / home directory.
