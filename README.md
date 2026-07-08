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
- **Nix** (multi-user) with flakes enabled. If Nix is not installed yet:
  ```sh
  sh <(curl -L https://nixos.org/nix/install)
  ```
  Enable flakes in `/etc/nix/nix.conf` (or `~/.config/nix/nix.conf`):
  ```
  experimental-features = nix-command flakes
  ```
  > Using the Determinate Systems installer? Add `nix.enable = false;` to
  > `modules/nix.nix` — Determinate manages Nix itself.
- **Administrator account** (`sudo`); activation runs as root.

Homebrew itself is **not** a prerequisite — `nix-homebrew` installs and manages it.

## First build

nix-darwin will not overwrite an existing `/etc/nix/nix.conf`, so move it aside once:

```sh
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#eigen
```

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
| `hosts/eigen.nix` | Host identity: platform, primary user, state version. |
| `modules/nix.nix` | Nix settings: gc, optimise, binary caches, experimental features. |
| `modules/macos.nix` | macOS `system.defaults`, fonts, Touch ID, firewall, dock pinning, Spotlight scope, wallpaper. |
| `modules/packages.nix` | System CLI packages. |
| `modules/homebrew.nix` | nix-homebrew and declarative casks. |
| `modules/home.nix` | Home Manager aggregator (imports `home/*`). |
| `modules/home/dev.nix` | Global editor tooling: LSPs, formatters, linters. |
| `modules/home/git.nix` | Git: delta, difftastic, ignores, aliases, YubiKey signing. |
| `modules/home/shell.nix` | zsh, starship, fzf, zoxide, direnv, bat, eza. |
| `modules/home/emacs.nix` | Emacs (`emacs-macport`), daemon, `init.el` symlink. |
| `modules/home/emacs/init.el` | Emacs config (vendored from `jmalena/init.el`). |
