{ callPackage }:

let
  installPatchScript = import ./install-patch-script.nix;

  lydellVirtualDom = callPackage ./lydell-virtual-dom.nix {};
  lydellHtml = callPackage ./lydell-html.nix {};
  lydellBrowser = callPackage ./lydell-browser.nix {};
in
''
${installPatchScript { drv = lydellVirtualDom; }}
${installPatchScript { drv = lydellHtml; }}
${installPatchScript { drv = lydellBrowser; }}
''
