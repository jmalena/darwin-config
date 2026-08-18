# darwin-config

Declarative macOS configuration for two Apple Silicon Macs — **eigen** (primary
user `aleph`) and **zweigen** (primary user `bet`) — built with
[nix-darwin](https://github.com/nix-darwin/nix-darwin),
[Home Manager](https://github.com/nix-community/home-manager), and
[nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

## Prerequisites

- **macOS on Apple Silicon** (`aarch64-darwin`).
- **Xcode Command Line Tools**:
  ```sh
  xcode-select --install
  ```
- **Nix** (multi-user). Install it first if needed — the script enables flakes
  for you:
  ```sh
  sh <(curl -L https://nixos.org/nix/install)
  ```
  > Using the Determinate Systems installer? Add `nix.enable = false;` to
  > `modules/nix.nix` — Determinate manages Nix itself.
- **Administrator account** (`sudo`); activation runs as root.

Homebrew itself is **not** a prerequisite — `nix-homebrew` installs and manages it.

## Hosts

Both machines share one module set; a host file carries only identity. Modules
derive every user-specific path from the primary user, so no username is
hardcoded outside `hosts/`.

| Host | Primary user | Host file |
| --- | --- | --- |
| `eigen` | `aleph` | `hosts/eigen.nix` |
| `zweigen` | `bet` | `hosts/zweigen.nix` |

Adding a third machine means one more file in `hosts/` and one line in
`flake.nix`.

The repo is expected to live at `~/Projects/darwin-config` — the `rebuild`
alias, the Finder sidebar favorite, and the live-editable `init.el` symlink all
point there.

## Install

Clone the repo to `~/Projects/darwin-config`, then run the bootstrap script:

```sh
./install.sh
```

It builds the host matching this machine's name. Override that with `--host`
(useful on a fresh Mac whose hostname isn't set yet):

```sh
./install.sh --host zweigen
```

It is idempotent and safe to re-run. Each run:

- resolves the target host and checks that `hosts/<host>.nix` exists;
- verifies preconditions (macOS, non-root user, Xcode CLT, Nix present);
- enables flakes for your user in `~/.config/nix/nix.conf`;
- creates `~/Screenshots` (the `screencapture.location` target);
- if `~/.ssh/id_ed25519_sk.pub` is missing, offers to generate a resident
  YubiKey FIDO2 SSH key (needs a touch) and prints the public key to add to
  GitHub as **both** an Authentication and a Signing key;
- stages the config paths so the git flake sees new files;
- builds the system closure, then activates it with `darwin-rebuild switch`
  (bootstrapping nix-darwin on the first run).

Flags: `--host NAME` selects the host output; `--update` runs `nix flake update`
before switching; `-h` / `--help` prints usage.

> First run only: nix-darwin will not overwrite an existing `/etc/nix/nix.conf`.
> If you have one, move it aside first:
> ```sh
> sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
> ```

## Usage

After the first build, `darwin-rebuild` is on your `PATH`:

```sh
sudo darwin-rebuild switch --flake .
```

With no attribute, `darwin-rebuild` picks the output matching this machine's
hostname; name it explicitly with `.#eigen` or `.#zweigen`.

Build without activating (useful to validate a change, and the only way to
check the *other* machine's config from this one):

```sh
nix build .#darwinConfigurations.eigen.system
nix build .#darwinConfigurations.zweigen.system
```

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Inputs and the `eigen` / `zweigen` system outputs. |
| `install.sh` | Idempotent bootstrap: host resolution, checks, flakes, YubiKey key-gen, build + activate. |
| `hosts/common.nix` | Shared module imports, platform, state version. |
| `hosts/eigen.nix` | Host identity for `eigen`: hostname, primary user `aleph`. |
| `hosts/zweigen.nix` | Host identity for `zweigen`: hostname, primary user `bet`. |
| `modules/nix.nix` | Nix settings: gc, optimise, binary caches, experimental features. |
| `modules/macos.nix` | macOS `system.defaults`, fonts, dock pinning, Spotlight scope, wallpaper, Chrome managed policy. |
| `modules/security.nix` | Touch ID, application firewall, login window, screen lock, AirDrop, Continuity, sharing services. |
| `modules/packages.nix` | System CLI packages. |
| `modules/homebrew.nix` | nix-homebrew and declarative casks. |
| `modules/home.nix` | Home Manager aggregator (imports `home/*`). |
| `modules/home/dev.nix` | Global editor tooling: LSPs, formatters, linters. |
| `modules/home/git.nix` | Git: delta, difftastic, ignores, aliases, YubiKey signing. |
| `modules/home/shell.nix` | zsh, starship, fzf, zoxide, direnv, bat, eza. |
| `modules/home/emacs.nix` | Emacs: terminal/daemon (`emacs-nox`), GUI via Homebrew cask, `init.el` symlink. |
| `modules/home/security.nix` | ByHost preferences (screen-saver idle time, AirPlay Receiver) unreachable from `CustomUserPreferences`. |
| `modules/home/emacs/init.el` | Emacs config (vendored from `jmalena/init.el`). |
