# darwin-config

Declarative macOS configuration for the host **eigen** (Apple Silicon), built with
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

## Install

Clone the repo, then run the bootstrap script:

```sh
./install.sh
```

It is idempotent and safe to re-run. Each run:

- verifies preconditions (macOS, non-root user, Xcode CLT, Nix present);
- enables flakes for your user in `~/.config/nix/nix.conf`;
- creates `~/Screenshots` (the `screencapture.location` target);
- if `~/.ssh/id_ed25519_sk.pub` is missing, offers to generate a resident
  YubiKey FIDO2 SSH key (needs a touch) and prints the public key to add to
  GitHub as **both** an Authentication and a Signing key;
- stages the config paths so the git flake sees new files;
- builds the system closure, then activates it with `darwin-rebuild switch`
  (bootstrapping nix-darwin on the first run).

Flags: `--update` runs `nix flake update` before switching; `-h` / `--help`
prints usage.

> First run only: nix-darwin will not overwrite an existing `/etc/nix/nix.conf`.
> If you have one, move it aside first:
> ```sh
> sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
> ```

## Usage

After the first build, `darwin-rebuild` is on your `PATH`:

```sh
sudo darwin-rebuild switch --flake .#eigen
```

Build without activating (useful to validate a change):

```sh
nix build .#darwinConfigurations.eigen.system
```

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Inputs and the `eigen` system output. |
| `install.sh` | Idempotent bootstrap: checks, flakes, YubiKey key-gen, build + activate. |
| `hosts/eigen.nix` | Host identity: platform, primary user, state version. |
| `modules/nix.nix` | Nix settings: gc, optimise, binary caches, experimental features. |
| `modules/macos.nix` | macOS `system.defaults`, fonts, Touch ID, firewall, dock pinning, Spotlight scope, wallpaper. |
| `modules/packages.nix` | System CLI packages. |
| `modules/homebrew.nix` | nix-homebrew and declarative casks. |
| `modules/home.nix` | Home Manager aggregator (imports `home/*`). |
| `modules/home/dev.nix` | Global editor tooling: LSPs, formatters, linters. |
| `modules/home/git.nix` | Git: delta, difftastic, ignores, aliases, YubiKey signing. |
| `modules/home/shell.nix` | zsh, starship, fzf, zoxide, direnv, bat, eza. |
| `modules/home/emacs.nix` | Emacs: terminal/daemon (`emacs-nox`), GUI via Homebrew cask, `init.el` symlink. |
| `modules/home/emacs/init.el` | Emacs config (vendored from `jmalena/init.el`). |
