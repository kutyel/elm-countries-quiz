{
  inputs = {
    elm2nix = {
      url = "github:dwayne/elm2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, elm2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (elm2nix.lib.elm2nix pkgs)
          generateRegistryDat
          prepareElmHomeScript;

        app = pkgs.callPackage ./nix/app.nix {
          inherit generateRegistryDat prepareElmHomeScript;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "elm-countries-quiz";

          packages = [
            elm2nix.packages.${system}.default
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-json
            pkgs.elmPackages.elm-test-rs
            pkgs.elmPackages.elm-review
            pkgs.nodejs_24
            pkgs.pnpm
          ];

          shellHook = ''
            export PROJECT_ROOT="$PWD"
            export PS1="($name)\n$PS1"

            f () {
              elm-format "$PROJECT_ROOT"/src --yes
            }

            r () {
              elm-review
            }

            t () {
              elm-test-rs "$PROJECT_ROOT"/tests/*.elm
            }

            clean () {
              rm -rf "$PROJECT_ROOT"/{.parcel-cache,dist,elm-stuff,node_modules}
            }

            pnpm install --silent

            echo "Elm development environment loaded"
            echo "All your dependencies have been installed"
            echo "Type 'f' to run elm-format"
            echo "Type 'r' to run elm-review"
            echo "Type 't' to run elm-test-rs"
          '';
        };

        packages = {
          inherit app;
          default = app;
        };
      }
    );
}
