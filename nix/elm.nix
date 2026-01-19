{ buildElmApplication, callPackage, lib }:

let
  fs = lib.fileset;

  drv = buildElmApplication {
    name = "elm-countries-quiz";
    src = fs.toSource {
      root = ../.;
      fileset = fs.unions [
        ../review
        ../src
        ../tests
        ../elm.json
      ];
    };
    elmLock = ../elm.lock;
    output = "elm-countries-quiz.js";

    doElmFormat = true;
    elmFormatSourceFiles = [ "review/src" "src" "tests" ];

    doElmTest = true;

    #
    # To get this to work you have to generate the lock file as follows:
    #
    # elm2nix lock elm.json review/elm.json
    #
    doElmReview = true;

    #
    # Learn more: https://dev.to/dwayne/announcing-dwayneelm2nix-46pc
    #
  };

  esvdPatches = callPackage ./elm-safe-virtual-dom/patches.nix {};
in
drv.overrideAttrs (old: {
  prepareElmHomePhase = old.prepareElmHomePhase + esvdPatches;
})
