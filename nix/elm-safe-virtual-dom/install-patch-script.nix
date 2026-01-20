{ drv # A derivation of a patched package
, elmHome ? ".elm"
}:
let
  packagesDir = "${elmHome}/0.19.1/packages";
  to = "${packagesDir}/${drv.path}";
  from = "${drv}/${drv.path}";
in
''
if [ -d ${to} ]; then
  rm -r ${to}
  cp -R ${from} ${to}
  chmod -R +w ${to}
fi
''
