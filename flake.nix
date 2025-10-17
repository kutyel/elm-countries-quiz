{
  description = "elm-countries-quiz";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mkElmDerivation.url = "github:jeslie0/mkElmDerivation";
  };

  outputs = { self, nixpkgs, mkElmDerivation, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          overlays = [ mkElmDerivation.overlays.mkElmDerivation ];
          inherit system;
        };
        inherit (pkgs) lib callPackage elmPackages;
        inherit (lib) fileset;

        toSource = fsets:
          fileset.toSource {
            root = ./.;
            fileset = fileset.unions fsets;
          };
        elmVersion = "0.19.1";
        elmPackageName = "elm-countries-quiz";
        elmPackage = pkgs.mkElmDerivation {
          name = elmPackageName;
          src = ./.;
          outputJavaScript = true;
        };
        testsSrc = toSource [
          (fileset.fileFilter (file: file.hasExt "elm") ./tests)
        ];

        reviewSrc = toSource [
          (fileset.fromSource testsSrc)
          (fileset.fileFilter (file: file.hasExt "elm") ./review)
          ./review/elm.json
        ];
        elmReview = elmPackages.elm-review;
        elmTests = callPackage ./nix/elmTests.nix { inherit testsSrc; };
        elmReviewed = callPackage ./nix/elmReviewed.nix {
          inherit elmReview elmVersion reviewSrc;
        };
      in
        {
          packages.default = pkgs.stdenv.mkDerivation {
            pname = elmPackageName;
            version = "0.1.0";
            src = ./.;
            elmJson = ./elm.json; # defaults to ${src}/elm.json
            buildInputs = [ elmPackage ];
            buildPhase = ''
              cp ${elmPackage}/Main.min.js main.min.js
            '';
            installPhase = ''
              mkdir -p $out
              cp index.html $out/
              cp main.min.js $out/
            '';
          };

          devShell = pkgs.mkShell {
            inputsFrom = [ elmPackage ];
            packages = with pkgs;
              [ elmPackages.elm-language-server
                elmPackages.elm-format
                elmPackages.elm-test
                elmPackages.elm-review
              ];
          };

          checks = { inherit elmReviewed elmTests; };
        }
    );
}
