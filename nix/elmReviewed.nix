{ elmReview, elmPackages, elmVersion, lib, pkgs, stdenv, reviewSrc }:
let mainApp = builtins.fromJSON (builtins.readFile ../elm.json);

in stdenv.mkDerivation {
  name = "elm-reviewed";
  src = reviewSrc;

  buildInputs = with elmPackages; [ elm elm-json elmPackages.elm-review ];

  installPhase = ''
    ${pkgs.makeDotElmDirectoryCmd {
      elmJson = ../review/elm.json;
      extraDeps = mainApp.dependencies.direct // mainApp.dependencies.indirect;
    }}
    set -e
    mkdir -p .elm/elm-review/2.13.4
    ln -s ../../${elmVersion} .elm/elm-review/2.13.4/${elmVersion}
    elm-review
    echo "passed" > $out
  '';
}
