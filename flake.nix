{
  description = "example of a dotnet flake with private nuget feeds";
  
  inputs = {

    nixpkgs = {
      url = "github:anpin/nixpkgs?ref=nuget-private-repo";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let 
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system ; };
    inherit (inputs.nixpkgs) lib; 
    in {
      apps.${system} = {
        run-nuget-to-nix = {
                type = "app";
                program = with pkgs; toString (pkgs.writers.writeBash "run-nuget-to-nix" ''                  
                  
                  if [ $# -eq 0 ]; then
                      >&2 echo "Usage: $0 <github username> <github PAT with packages:read scope>"
                      exit 1
                  fi
                  
                  GH_USERNAME="''${1:?"github username was empty"}"
                  GH_PAT="''${2:?"github PAT was empty"}"
                  
                  # github requires authentication even for public packages
                  # in order to access protected resources we use username and token 
                  # within nuget.config and .netrc 
                  
                  export GH_USERNAME
                  export GH_PAT
                  ORIGINAL_HOME=$HOME
                  tmp=$(realpath "$(mktemp -td run-nuget-to-nix.XXXXXX)")
                  trap 'export HOME=$ORIGINAL_HOME;rm -rf "$tmp"' EXIT INT TERM
                  export HOME=$tmp                  
                  
                  # copy source to avoid read-only file system error
                  cp -r ${self}/src $tmp/src
                  chmod -R u+w $tmp/src
                  
                  # set authentication for curl 
                  cat > $tmp/.netrc <<EOF
                  machine nuget.pkg.github.com
                  login $GH_USERNAME
                  password $GH_PAT
                  EOF
                  chmod 600 $tmp/.netrc
                  
                  mkdir -p $tmp/packages
                  
                  ${dotnet-sdk_8}/bin/dotnet restore $tmp/src --packages $tmp/packages
                  ${nuget-to-nix}/bin/nuget-to-nix $tmp/packages /dev/null $tmp/src/nuget.config
                
                '');
            };
      };
      devShells.${system}.default = import ./shell.nix {inherit pkgs;};
  };
}
