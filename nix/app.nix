{ fetchPnpmDeps
, nodejs
, pnpm
, pnpmConfigHook
, stdenv

, generateRegistryDat
, prepareElmHomeScript
}:

let
  elmLock = ../elm.lock;
  registryDat = generateRegistryDat { inherit elmLock; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "elm-countries-quiz";
  version = "1.0.0";
  src = ../.;
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
    pnpm build index.html
    cp -R dist/ "$out"/

    runHook postBuild
  '';
})
