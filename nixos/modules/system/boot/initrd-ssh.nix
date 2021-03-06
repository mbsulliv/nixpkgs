{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.boot.initrd.network.ssh;

in

{

  options = {

    boot.initrd.network.ssh.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Start SSH service during initrd boot. It can be used to debug failing
        boot on a remote server, enter pasphrase for an encrypted partition etc.
        Service is killed when stage-1 boot is finished.
      '';
    };

    boot.initrd.network.ssh.port = mkOption {
      type = types.int;
      default = 22;
      description = ''
        Port on which SSH initrd service should listen.
      '';
    };

    boot.initrd.network.ssh.shell = mkOption {
      type = types.str;
      default = "/bin/ash";
      description = ''
        Login shell of the remote user. Can be used to limit actions user can do.
      '';
    };

    boot.initrd.network.ssh.hostRSAKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        RSA SSH private key file in the Dropbear format.

        WARNING: This key is contained insecurely in the global Nix store. Do NOT
        use your regular SSH host private keys for this purpose or you'll expose
        them to regular users!
      '';
    };

    boot.initrd.network.ssh.hostDSSKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        DSS SSH private key file in the Dropbear format.

        WARNING: This key is contained insecurely in the global Nix store. Do NOT
        use your regular SSH host private keys for this purpose or you'll expose
        them to regular users!
      '';
    };

    boot.initrd.network.ssh.hostECDSAKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        ECDSA SSH private key file in the Dropbear format.

        WARNING: This key is contained insecurely in the global Nix store. Do NOT
        use your regular SSH host private keys for this purpose or you'll expose
        them to regular users!
      '';
    };

    boot.initrd.network.ssh.authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = config.users.extraUsers.root.openssh.authorizedKeys.keys;
      description = ''
        Authorized keys for the root user on initrd.
      '';
    };

  };

  config = mkIf (config.boot.initrd.network.enable && cfg.enable) {

    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.dropbear}/bin/dropbear
      cp -pv ${pkgs.glibc}/lib/libnss_files.so.* $out/lib
    '';

    boot.initrd.extraUtilsCommandsTest = ''
      $out/bin/dropbear -V
    '';

    boot.initrd.network.postCommands = ''
      mkdir /dev/pts
      mount -t devpts devpts /dev/pts

      echo '${cfg.shell}' > /etc/shells
      echo 'root:x:0:0:root:/root:${cfg.shell}' > /etc/passwd
      echo 'passwd: files' > /etc/nsswitch.conf

      mkdir -p /var/log
      touch /var/log/lastlog

      mkdir -p /etc/dropbear
      ${optionalString (cfg.hostRSAKey != null) "ln -s ${cfg.hostRSAKey} /etc/dropbear/dropbear_rsa_host_key"}
      ${optionalString (cfg.hostDSSKey != null) "ln -s ${cfg.hostDSSKey} /etc/dropbear/dropbear_dss_host_key"}
      ${optionalString (cfg.hostECDSAKey != null) "ln -s ${cfg.hostECDSAKey} /etc/dropbear/dropbear_ecdsa_host_key"}

      mkdir -p /root/.ssh
      ${concatStrings (map (key: ''
        echo -n ${escapeShellArg key} >> /root/.ssh/authorized_keys
      '') cfg.authorizedKeys)}

      dropbear -s -j -k -E -m -p ${toString cfg.port}
    '';

  };

}
