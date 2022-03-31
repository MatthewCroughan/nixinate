# Configuration that will be added to the nixinatee node. Nixinate will deploy
# the combination of nixinateBase.nix + nixinateAdditional.nix
{
  config = {
    services.nginx.enable = true;
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
