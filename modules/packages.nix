{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    fd

    # OpenPGP for the YubiKey smartcards. pinentry_mac prompts in a GUI window,
    # so PIN entry works from contexts with no controlling terminal.
    gnupg
    pinentry_mac

    jq
    libimobiledevice
    mysides
    pandoc
    ripgrep
    tree
    wget
  ];
}
