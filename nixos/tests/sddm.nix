import ./make-test.nix ({ pkgs, ...} : {
  name = "sddm";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ ttuegel ];
  };

  machine = { lib, ... }: {
    imports = [ ./common/user-account.nix ];
    services.xserver.enable = true;
    services.xserver.displayManager.sddm = {
      enable = true;
      autoLogin = {
        enable = true;
        user = "alice";
      };
    };
    services.xserver.windowManager.default = "icewm";
    services.xserver.windowManager.icewm.enable = true;
    services.xserver.desktopManager.default = "none";
  };

  enableOCR = true;

  testScript = { nodes, ... }: ''
    startAll;
    $machine->waitForWindow("^IceWM ");
  '';
})
