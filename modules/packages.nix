{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    fd
    jq
    ripgrep
    tree
    wget
  ];
}
