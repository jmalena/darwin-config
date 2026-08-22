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

Every host runs the same module set. The only thing that distinguishes them is
a hostname-to-user table at the top of `flake.nix`:

```nix
hosts = {
  eigen = "aleph";
  zweigen = "bet";
};
```

| Host | Primary user |
| --- | --- |
| `eigen` | `aleph` |
| `zweigen` | `bet` |

Modules derive every user-specific path from `config.system.primaryUser` or
`config.home.homeDirectory`, so those two lines are the only place any username
appears. Adding a machine — or using an entirely different account name — is one
more entry in that table and nothing else.

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

- resolves the target host and checks it against the flake's host table;
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

## VPN

`modules/vpn.nix` keeps a WireGuard tunnel to Proton up and blocks every egress
path that does not go through it. The profile carries a private key, so it is
not declared in this repo — download one from **account.protonvpn.com >
Downloads > WireGuard configuration** and drop it in place:

```sh
sudo install -m 600 ~/Downloads/proton.conf /etc/wireguard/proton.conf
```

Until that file exists the kill switch stays open, so a fresh machine is never
left without a network.

The tunnel starts at boot and covers the machine before anyone logs in. The
Proton app coexists with it: the moment the app's own tunnel connects, the
daemon takes the baseline tunnel down and stands its pf rules aside, then
brings both back as soon as the app disconnects. While the app holds the
tunnel, leak protection is its job — keep the kill switch enabled in its
settings.

On a captive portal (hotel, airport, train) the kill switch blocks the sign-in
page. Open a window for it:

```sh
sudo vpn-bypass       # kill switch off for 15 minutes
sudo vpn-bypass off   # back on as soon as you are through
```

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Inputs, the hostname-to-user table, and the system outputs built from it. |
| `install.sh` | Idempotent bootstrap: host resolution, checks, flakes, YubiKey key-gen, build + activate. |
| `hosts/common.nix` | Shared module imports, platform, state version. |
| `modules/nix.nix` | Nix settings: gc, optimise, binary caches, experimental features. |
| `modules/macos.nix` | macOS `system.defaults`, fonts, dock pinning, Spotlight scope, wallpaper, Chrome managed policy. |
| `modules/security.nix` | Touch ID, application firewall, login window, screen lock, AirDrop, Continuity, sharing services. |
| `modules/vpn.nix` | Always-on WireGuard tunnel to Proton, pf kill switch, DNS pinning on network change. |
| `modules/packages.nix` | System CLI packages. |
| `modules/homebrew.nix` | nix-homebrew and declarative casks. |
| `modules/home.nix` | Home Manager aggregator (imports `home/*`). |
| `modules/home/dev.nix` | Global editor tooling: LSPs, formatters, linters. |
| `modules/home/git.nix` | Git: delta, difftastic, ignores, aliases, YubiKey signing. |
| `modules/home/shell.nix` | zsh, starship, fzf, zoxide, direnv, bat, eza. |
| `modules/home/emacs.nix` | Emacs: terminal/daemon (`emacs-nox`), GUI via Homebrew cask, `init.el` symlink. |
| `modules/home/security.nix` | ByHost preferences (screen-saver idle time, AirPlay Receiver) unreachable from `CustomUserPreferences`. |
| `modules/home/emacs/init.el` | Emacs config (vendored from `jmalena/init.el`). |
