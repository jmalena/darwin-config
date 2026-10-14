#!/usr/bin/env bash
# Builds and activates this Mac's configuration. Safe to re-run.
set -euo pipefail

REPO="$HOME/Projects/darwin-config"
SK_KEY="$HOME/.ssh/id_ed25519_sk"
GIT_EMAIL="jonas.malena@gmail.com"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
nix()  { command nix --extra-experimental-features "nix-command flakes" "$@"; }

usage() {
  cat <<EOF
Usage: $0 --host NAME [--update]
  --host NAME  host from flake.nix to build (required)
  --update     update flake inputs before switching
EOF
}

host=""
update=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)    [ "$#" -gt 1 ] || die "--host needs a value"; host="$2"; shift ;;
    --host=*)  host="${1#--host=}" ;;
    --update)  update=1 ;;
    -h|--help) usage; exit 0 ;;
    *)         die "unknown argument: $1 (see --help)" ;;
  esac
  shift
done

[ "$(uname -s)" = Darwin ]      || die "this script targets macOS."
[ "$(id -u)" -ne 0 ]            || die "run as your normal user; the script calls sudo itself."
xcode-select -p >/dev/null 2>&1 || die "Xcode Command Line Tools missing. Run: xcode-select --install"
command -v nix >/dev/null       || die "Nix not found. Install it: sh <(curl -L https://nixos.org/nix/install)"
[ "$(dirname "$0")" -ef "$REPO" ] || die "move this repo to $REPO first; Emacs loads its config from there."
cd "$REPO"

# A git flake only sees tracked files.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add -A -- flake.nix flake.lock modules
fi

hosts="$(nix eval --raw .#darwinConfigurations --apply 'c: toString (builtins.attrNames c)')"
[[ -n "$host" && " $hosts " == *" $host "* ]] || die "pass --host with one of: $hosts"

if [ ! -f "$SK_KEY.pub" ]; then
  read -r -p "No YubiKey SSH key at $SK_KEY. Generate one now (needs a touch)? [y/N] " answer || true
  if [[ "${answer:-}" == [Yy] ]]; then
    nix shell --inputs-from . nixpkgs#openssh -c \
      ssh-keygen -t ed25519-sk -O resident -O application=ssh:git -C "$GIT_EMAIL" -f "$SK_KEY"
    info "Add this key to GitHub as both an Authentication and a Signing key:"
    cat "$SK_KEY.pub"
  else
    info "Skipped; commit signing and pushing need $SK_KEY."
  fi
fi

mkdir -p "$HOME/Screenshots"

if [ "$update" -eq 1 ]; then
  info "Updating flake inputs…"
  nix flake update
fi

info "Building ${host}…"
system="$(nix build --no-link --print-out-paths ".#darwinConfigurations.$host.system")"

# The Nix installer edits these, and nix-darwin won't replace files it doesn't recognise.
shell_files=(/etc/bashrc /etc/zshrc)
for f in "${shell_files[@]}"; do
  if [ -f "$f" ] && [ ! -L "$f" ]; then sudo mv "$f" "$f.before-nix-darwin"; fi
done

info "Activating ${host}…"
if ! sudo "$system/sw/bin/darwin-rebuild" switch --flake ".#$host"; then
  # Put them back if activation stopped before linking /etc, so new shells still load Nix.
  for f in "${shell_files[@]}"; do
    if [ ! -e "$f" ] && [ -f "$f.before-nix-darwin" ]; then sudo mv "$f.before-nix-darwin" "$f"; fi
  done
  die "activation failed (see above)."
fi

info "Done. Open a new terminal to pick up the new environment."
