{ fetchFromGitHub, stdenv }:

{ fromOwner
, toOwner
, repo
, version
, rev
, hash
}:

let
  path = "${toOwner}/${repo}/${version}";
in
stdenv.mkDerivation {
  inherit version;

  pname = "${fromOwner}-${repo}";

  src = fetchFromGitHub {
    inherit repo rev hash;
    owner = fromOwner;
  };

  installPhase = ''
    root="$out/${path}"
    mkdir -p "$root"
    cp elm.json "$root/elm.json"
    cp -R src "$root/src"
  '';

  passthru = {
    inherit path;
  };
}
