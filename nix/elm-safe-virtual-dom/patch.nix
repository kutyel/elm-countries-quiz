{ fetchFromGitHub, stdenv }:

{ fromOwner
, toOwner
, repo
, version
, rev
, hash
}:
stdenv.mkDerivation {
  inherit version;

  pname = "${fromOwner}-${repo}";

  src = fetchFromGitHub {
    inherit repo rev hash;
    owner = fromOwner;
  };

  installPhase = ''
    root="$out/${toOwner}/${repo}/${version}"
    mkdir -p "$root"
    cp elm.json "$root/elm.json"
    cp -R src "$root/src"
  '';
}
