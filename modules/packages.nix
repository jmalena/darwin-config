{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    fd
    jq
    mysides
    ripgrep
    tree
    wget
  ];
}
