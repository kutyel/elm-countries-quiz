{ callPackage }:

let
  mkPatch = callPackage ./patch.nix {};
in
mkPatch {
  fromOwner = "lydell";
  toOwner = "elm";
  repo = "html";
  version = "1.0.1";
  rev = "b35c476a69f0ba9bf8282d8c15df65e63aefea8f";
  hash = "sha256-xyL/AvKdsxTl4RgfBCdTuWndM55eNM6whPD3YqptcKM=";
}
