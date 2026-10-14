{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    fd
    gnupg
    jq
    libimobiledevice
    mysides
    tree
    wget
  ];
}
