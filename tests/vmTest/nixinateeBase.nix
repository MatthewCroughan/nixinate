# Common configuration of nixinatee node in the vmTest. This is the base
# configuration which is required to perform the test.
{
  config = {
    nix.trustedUsers = [ "nixinator" ];
    security.sudo.extraRules = [{
      users = [ "nixinator" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];
    users = {
      mutableUsers = false;
      users = {
        nixinator = {
          extraGroups = [
            "wheel"
          ];
          password = "";
          isNormalUser = true;
        };
      };
    };
    services.openssh = {
      enable = true;
      extraConfig = "PermitEmptyPasswords yes";
    };
    documentation.enable = false;
    boot.loader.grub.enable = false;
  };
}
