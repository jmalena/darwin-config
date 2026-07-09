#!/usr/bin/env bash
set -euo pipefail

# --- settings -------------------------------------------------------------
FLAKE_HOST="eigen"
GIT_EMAIL="jonas.malena@gmail.com"
SK_KEY="$HOME/.ssh/id_ed25519_sk"
NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE="${SCRIPT_DIR}#${FLAKE_HOST}"
BUILD_ATTR="${SCRIPT_DIR}#darwinConfigurations.${FLAKE_HOST}.system"

# --- helpers --------------------------------------------------------------
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

DO_UPDATE=0
for arg in "$@"; do
  case "$arg" in
    --update)  DO_UPDATE=1 ;;
    -h|--help) printf 'Usage: %s [--update]\n  --update  run nix flake update before switching\n' "$0"; exit 0 ;;
    *)         die "unknown argument: $arg (see --help)" ;;
  esac
done

# --- preconditions --------------------------------------------------------
[ "$(uname -s)" = "Darwin" ]     || die "this script targets macOS (nix-darwin)."
[ "$(id -u)" -ne 0 ]             || die "run as your normal user, not root — it elevates with sudo internally."
xcode-select -p >/dev/null 2>&1  || die "Xcode Command Line Tools missing. Run: xcode-select --install"
command -v nix >/dev/null 2>&1   || die "Nix not found. Install it first: sh <(curl -L https://nixos.org/nix/install)"
NIX_BIN="$(command -v nix)"

# --- enable flakes for this user (idempotent) -----------------------------
user_conf="$HOME/.config/nix/nix.conf"
if ! grep -qs 'experimental-features' "$user_conf" 2>/dev/null; then
  info "enabling flakes in $user_conf"
  mkdir -p "$(dirname "$user_conf")"
  printf 'experimental-features = nix-command flakes\n' >> "$user_conf"
fi

# --- screenshots dir (screencapture.location points here) -----------------
mkdir -p "$HOME/Screenshots"

# --- projects dir (~proj / rebuild alias / sidebar point here) ------------
mkdir -p "$HOME/Projects"

# --- YubiKey FIDO2 key (guided, only if missing) --------------------------
if [ ! -f "${SK_KEY}.pub" ]; then
  info "No FIDO2 SSH key at ${SK_KEY}.pub."
  read -r -p "Generate a resident YubiKey key now (requires a touch)? [y/N] " ans
  if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
    info "Insert your YubiKey and touch it when it blinks…"
    nix shell "${NIX_FLAGS[@]}" nixpkgs#openssh -c \
      ssh-keygen -t ed25519-sk -O resident -O application=ssh:git -C "$GIT_EMAIL" -f "$SK_KEY"
    info "Add this PUBLIC key to GitHub as BOTH an Authentication and a Signing key:"
    cat "${SK_KEY}.pub"
  else
    warn "Skipping key-gen — commit signing and SSH push will fail until ${SK_KEY}.pub exists."
  fi
fi

# --- make new config visible to the git flake -----------------------------
# Stage only config paths (never a blanket repo-root add) so a stray file such
# as a mistakenly-placed SSH key can't be staged. Undo any time with git reset.
if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$SCRIPT_DIR" add -A -- \
    modules hosts flake.nix flake.lock install.sh README.md CLAUDE.md .gitignore
fi

# --- optionally update flake inputs ---------------------------------------
if [ "$DO_UPDATE" -eq 1 ]; then
  info "Updating flake inputs…"
  ( cd "$SCRIPT_DIR" && nix "${NIX_FLAGS[@]}" flake update )
fi

# --- build first (catches errors before sudo) ----------------------------
info "Building system closure…"
nix "${NIX_FLAGS[@]}" build --no-link "$BUILD_ATTR"

# --- activate (idempotent) ------------------------------------------------
DR="$(command -v darwin-rebuild || true)"
[ -n "$DR" ] || { [ -x /run/current-system/sw/bin/darwin-rebuild ] && DR=/run/current-system/sw/bin/darwin-rebuild; }
if [ -n "$DR" ]; then
  info "Applying: darwin-rebuild switch…"
  sudo "$DR" switch --flake "$FLAKE"
else
  info "First run — bootstrapping nix-darwin…"
  sudo "$NIX_BIN" run "${NIX_FLAGS[@]}" nix-darwin/master#darwin-rebuild -- switch --flake "$FLAKE"
fi

info "Done. Open a new terminal to pick up shell/env changes."
