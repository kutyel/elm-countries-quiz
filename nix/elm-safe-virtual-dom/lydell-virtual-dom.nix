{ callPackage }:

let
  mkPatch = callPackage ./patch.nix {};
in
mkPatch {
  fromOwner = "lydell";
  toOwner = "elm";
  repo = "virtual-dom";
  version = "1.0.5";
  rev = "e1fae6aabd65539db2c94a98220a45cfc624b633";
  hash = "sha256-XpbRMCpIx151eHHoph7wkGYhtDp5bTBwUOefiWKItOc=";
}
