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

    # HTML to PDF without a TeX install; pandoc's default pdflatex engine would
    # pull in all of MacTeX. `pandoc --pdf-engine=weasyprint` renders through
    # pandoc's own template, so call weasyprint directly to keep the source CSS.
    python3Packages.weasyprint

    ripgrep
    tree
    wget
  ];
}
