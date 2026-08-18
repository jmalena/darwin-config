{ config, pkgs, ... }:

let
  src = "/Volumes/STORE";
  dst = "/Volumes/STORE_BAK";
  logDir = "${config.home.homeDirectory}/Library/Logs";
  log = "${logDir}/store-sync.log";

  # Keyed on volume UUID rather than /dev/diskN: device nodes renumber on replug,
  # and a UUID also changes on reformat — so another exFAT stick named STORE can't
  # be mistaken for the source and mirrored over the backup.
  srcUuid = "41B0C1EA-B678-3590-9C2D-7CD68B324DF0";
  dstUuid = "3C9D6F7D-5D59-3923-A298-A271162754A9";

  # Both volumes are exFAT, which stores no POSIX permissions, ownership, symlinks
  # or xattrs, so -a would make rsync endlessly retry metadata the filesystem
  # cannot hold. No --partial either: an unplug mid-copy must leave no
  # half-written ciphertext behind in the vault.
  sync = pkgs.writeShellScript "store-sync" ''
    set -u

    uuid() {
      /usr/sbin/diskutil info -plist "$1" 2>/dev/null \
        | /usr/bin/plutil -extract VolumeUUID raw - 2>/dev/null
    }

    [ "$(uuid "${src}")" = "${srcUuid}" ] || exit 0
    [ "$(uuid "${dst}")" = "${dstUuid}" ] || exit 0

    # Refuse to mirror away a vault that vanished from the source: --delete would
    # otherwise carry that deletion to the only remaining copy. Every vault on the
    # backup must still exist on the source. Vaults are discovered rather than
    # listed here, so adding one can't silently lose the protection; depth 3 covers
    # both a vault at the drive root and one nested a level down, without
    # descending into the vault's own d/ tree.
    missing=$(cd "${dst}" 2>/dev/null && /usr/bin/find . -maxdepth 3 \
      -name vault.cryptomator -print 2>/dev/null \
      | while IFS= read -r marker; do
          [ -e "${src}/$marker" ] || echo "$marker"
        done)

    if [ -n "$missing" ]; then
      echo "$(/bin/date -Iseconds) refusing, vault missing from source:" \
        "$(echo "$missing" | /usr/bin/tr '\n' ' ')" >>"${log}"
      exit 0
    fi

    ${pkgs.rsync}/bin/rsync -rt --delete --modify-window=2 \
      --no-perms --no-owner --no-group \
      --exclude='.fseventsd/' --exclude='.Spotlight-V100/' \
      --exclude='.Trashes/' --exclude='.TemporaryItems/' \
      --exclude='.DS_Store' --exclude='._*' \
      "${src}/" "${dst}/" >>"${log}" 2>&1
    rc=$?
    echo "$(/bin/date -Iseconds) rc=$rc" >>"${log}"
  '';

  # A supervisor loop rather than leaving respawns to launchd: fswatch exits when
  # the volume goes away, and KeepAlive on its own would restart it hard enough
  # to hit launchd's throttle.
  watch = pkgs.writeShellScript "store-watch" ''
    set -u
    while :; do
      if [ -d "${src}" ] && [ -d "${dst}" ]; then
        ${sync}
        # -o collapses each batch to a single line and --latency debounces bursts,
        # so a large write triggers one rsync rather than one per file.
        ${pkgs.fswatch}/bin/fswatch -o --latency 5 "${src}" 2>>"${log}" \
          | while read -r _; do ${sync}; done
      fi
      /bin/sleep 30
    done
  '';
in
{
  # Mirrors the Cryptomator vault's ciphertext, so the backup is encrypted at rest
  # and the vault never has to be unlocked for a sync to run.
  #
  # StartOnMount is deliberately absent: KeepAlive holds this job alive, and
  # launchd will not re-launch a running job, so it would be a no-op. The 30s
  # supervisor poll is what notices an attach.
  launchd.agents.store-sync = {
    enable = true;
    config = {
      ProgramArguments = [ "${watch}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardErrorPath = "${logDir}/store-sync.err";
    };
  };
}
