{
  description = "Nixinate your systems 🕶️";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    examples.url = "path:./examples";
  };
  outputs = { self, nixpkgs, examples, ... }:
    let
      version = builtins.substring 0 8 self.lastModifiedDate;
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in rec
    {
      overlay = final: prev: {
        generateApps = flake:
          let
            machines = builtins.attrNames flake.nixosConfigurations;
            validMachines = final.lib.remove "" (final.lib.forEach machines (x: final.lib.optionalString (flake.nixosConfigurations."${x}"._module.args ? nixinate) "${x}" ));
            mkDeployScript = machine: final.writeScript "deploy-${machine}.sh" ''
              set -e
              SSH_USER=${flake.nixosConfigurations.${machine}._module.args.nixinate.sshUser}
              SSH_HOST=${flake.nixosConfigurations.${machine}._module.args.nixinate.host}
              BUILD_ON=${flake.nixosConfigurations.${machine}._module.args.nixinate.buildOn}
              echo "🚀 Deploying nixosConfigurations.${machine} from ${flake}"
              echo "👤 SSH User: $SSH_USER"
              echo "🌐 SSH Host: $SSH_HOST"
              if [ $BUILD_ON = "remote" ]; then
                echo "🚀 Sending flake to ${machine} via rsync:"
                ( set -x; ${final.rsync}/bin/rsync -q -vz --recursive --zc=zstd ${flake}/* $SSH_USER@$SSH_HOST:/tmp/nixcfg/ )
                echo "🤞 Activating configuration on ${machine} via ssh:"
                ( set -x; ${final.openssh}/bin/ssh -t $SSH_USER@$SSH_HOST 'sudo nixos-rebuild switch --flake /tmp/nixcfg#${machine}' )
              elif [ $BUILD_ON = "local" ]; then
                echo "🔨 Building system closure locally, copying it to remote store and activating it:"
                ( set -x; NIX_SSHOPTS="-t" ${final.nixos-rebuild}/bin/nixos-rebuild switch --flake ${flake}#${machine} --target-host $SSH_USER@$SSH_HOST --use-remote-sudo )
              else
                echo "_module.args.nixinate.buildOn is not set to a valid value of 'local' or 'remote'"
              fi
            '';
          in
          {
             nixinate =
               (
                 nixpkgs.lib.genAttrs
                   validMachines
                   (x:
                     {
                       type = "app";
                       program = toString (mkDeployScript x);
                     }
                   )
               );
          };
        };
      nixinate = forAllSystems (system: nixpkgsFor.${system}.generateApps);
      apps = nixinate.x86_64-linux examples;
    };
}
