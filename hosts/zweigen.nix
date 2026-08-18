{ ... }:

{
  imports = [ ./common.nix ];

  networking.hostName = "zweigen";

  system.primaryUser = "bet";

  users.users.bet = {
    name = "bet";
    home = "/Users/bet";
  };
}
