# TODO: use a relative path to nixinate, so that everything is contained within this repo.
# This would rely upon https://github.com/NixOS/nix/pull/5437 being merged.
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    nixinate.url = "github:matthewcroughan/nixinate";
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
