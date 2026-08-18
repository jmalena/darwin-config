{ ... }:

{
  imports = [ ./common.nix ];

  networking.hostName = "eigen";

  system.primaryUser = "aleph";

  users.users.aleph = {
    name = "aleph";
    home = "/Users/aleph";
  };
}
