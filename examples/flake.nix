{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    nixinate.url = "path:///etc/nixos/nixinate";
  };

  outputs = { self, nixpkgs, nixinate }: {
    apps = nixinate.nixinate.x86_64-linux self;
    nixosConfigurations = {
      myMachine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          { 
            _module.args.nixinate = {
              host = "itchy.scratchy.com";
              sshUser = "matthew";
              buildOn = "local"; # valid args are "local" or "remote"
            };
          }
          # ... other configuration ...
        ];
      };
    };
  };
}
