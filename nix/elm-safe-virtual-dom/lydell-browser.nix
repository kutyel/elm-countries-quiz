{ callPackage }:

let
  mkPatch = callPackage ./patch.nix {};
in
mkPatch {
  fromOwner = "lydell";
  toOwner = "elm";
  repo = "browser";
  version = "1.0.2";
  rev = "f5de544c8033d934285501f78f09e2eaf0171d55";
  hash = "sha256-29axLnzXcLDeKG+CBX49pjt2ZcYVdVg04XVnfAfImvI=";
}
