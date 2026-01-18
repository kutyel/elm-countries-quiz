{ callPackage
, fetchPnpmDeps
, lib
, nodejs
, pnpm
, pnpmConfigHook
, stdenv

, generateRegistryDat
, prepareElmHomeScript
}:

let
  fs = lib.fileset;

  elmLock = ../elm.lock;
  registryDat = generateRegistryDat { inherit elmLock; };

  #
  # TODO: Extract installPatchScript so that I can reuse it ./elm.nix.
  #
  installPatchScript =
    { drv # A derivation of a patched package
    , packagesDir ? ".elm/0.19.1/packages"
    }:
    let
      to = "${packagesDir}/${drv.path}";
      from = "${drv}/${drv.path}";
    in
    ''
    if [ -d ${to} ]; then
      rm -r ${to}
      cp -R ${from} ${to}
      chmod -R +w ${to}
    fi
    '';

  lydellVirtualDom = callPackage ./elm-safe-virtual-dom/lydell-virtual-dom.nix {};
  lydellHtml = callPackage ./elm-safe-virtual-dom/lydell-html.nix {};
  lydellBrowser = callPackage ./elm-safe-virtual-dom/lydell-browser.nix {};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "elm-countries-quiz";
  version = "1.0.0";

  src = fs.toSource {
    root = ../.;
    fileset = fs.unions [
      ../src
      ../.postcssrc
      ../elm.json
      ../index.html
      ../package.json
      ../pnpm-lock.yaml
      ../tailwind.config.js
    ];
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 1;
    hash = "sha256-/UN0Fu3acWWtnItMcA/fA0lMoLBmHIoqQCFCgI+WxYE=";
  };

  buildPhase = ''
    runHook preBuild

    ${prepareElmHomeScript { inherit elmLock registryDat; }}

    #
    # Replace elm/virtual-dom, elm/html, and elm/browser with Lydell's versions
    #
    ${installPatchScript { drv = lydellVirtualDom; }}
    ${installPatchScript { drv = lydellHtml; }}
    ${installPatchScript { drv = lydellBrowser; }}

    pnpm build index.html
    cp -R dist/ "$out"/

    runHook postBuild
  '';
})
