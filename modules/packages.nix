{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    fd
    jq
    libimobiledevice
    mysides
    ripgrep
    tree
    wget
  ];
}
