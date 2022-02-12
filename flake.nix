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
            mkDeployScript = dry: machine: let
              inherit (builtins) abort;

              n = flake.nixosConfigurations.${machine}._module.args.nixinate;
              user = n.sshUser or "root";
              host = n.host;
              closure = "${flake}#nixosConfigurations.${machine}.config.system.build.toplevel";
              where = n.buildOn or "remote";
              remote = if where == "remote" then true else if where == "local" then false else abort "_module.args.nixinate.buildOn is not set to a valid value of 'local' or 'remote'";
              switch = if dry then "dry-activate" else "switch";
	      script = ''
	        set -e
                echo "🚀 Deploying nixosConfigurations.${machine} from ${flake}"
                echo "👤 SSH User: ${user}"
                echo "🌐 SSH Host: ${host}"
	      '' + (if remote then ''
                echo "🚀 Sending flake to ${machine} via rsync:"
                ( set -x; ${final.rsync}/bin/rsync -q -vz --recursive --zc=zstd ${flake}/* ${user}@${host}:/tmp/nixcfg/ )
                echo "🤞 Activating configuration on ${machine} via ssh:"
                ( set -x; ${final.openssh}/bin/ssh -t ${user}@${host} 'sudo nixos-rebuild ${switch} --flake /tmp/nixcfg#${machine}' )
              '' else ''
                echo "🔨 Building system closure locally, copying it to remote store and activating it:"
                ( set -x; NIX_SSHOPTS="-t" ${final.nixos-rebuild}/bin/nixos-rebuild ${switch} --flake ${flake}#${machine} --target-host ${user}@${host} --use-remote-sudo )
              '');
	    in final.writeScript "deploy-${machine}.sh" script;
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
		   // nixpkgs.lib.genAttrs
                      (map (a: a ++ "-dry-run") validMachines)
                      (x:
                        {
                          type = "app";
                          program = toString (mkDeployScript true x);
                        }
                      )
               );
          };
        };
      nixinate = forAllSystems (system: nixpkgsFor.${system}.generateApps);
      apps = nixinate.x86_64-linux examples;
    };
}     
