# darwin-config

nix-darwin + Home Manager + nix-homebrew configuration for Apple Silicon Macs.

| Host | User |
| --- | --- |
| `eigen` | `aleph` |
| `zweigen` | `bet` |

## Setup

1. Install the Xcode Command Line Tools and Nix:

   ```sh
   xcode-select --install
   sh <(curl -L https://nixos.org/nix/install)
   ```

2. Clone the repo to `~/Projects/darwin-config` (Emacs loads its config from there):

   ```sh
   git clone https://github.com/jmalena/darwin-config ~/Projects/darwin-config
   ```

3. Run the installer with this Mac's host:

   ```sh
   cd ~/Projects/darwin-config
   ./install.sh --host eigen
   ```

The script offers to create a YubiKey SSH key, then builds and activates the system.
It is safe to re-run.

## Updates

Apply local changes:

```sh
./install.sh --host eigen
```

Update the pinned inputs in `flake.lock` and apply:

```sh
./install.sh --host eigen --update
```

To add a Mac, add a `hostname = "user";` line to `hosts` in `flake.nix`.
