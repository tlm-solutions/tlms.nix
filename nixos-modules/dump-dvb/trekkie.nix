{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.trekkie;
in
{
  options.dump-dvb.trekkie = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''Wether to enable trekkie service'';
    };
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = ''
        To which IP trekkie should bind.
      '';
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = ''
        To which port should trekkie bind.
      '';
    };
    saltPath = mkOption {
      type = types.either types.path types.string;
      default = "/run/secrets/salt_path";
      description = ''
        File from which the password salt can be taken
      '';
    };
    database = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = ''
          Database host
        '';
      };
      port = mkOption {
        type = types.port;
        default = 5354;
        description = ''
          Database port
        '';
      };
      passwordFile = mkOption {
        type = types.either types.path types.string;
        default = "";
      };
    };
    user = mkOption {
      type = types.str;
      default = "trekkie";
    };
    group = mkOption {
      type = types.str;
      default = "trekkie";
    };
    log_level = mkOption {
      type = types.str;
      default = "info";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.dump-dvb-radio = {
      name = "dump-dvb-radio";
      members = [
        "wartrammer"
        "data-accumulator"
        "trekkie"
      ];
      gid = 1501;
    };

    systemd = {
      services = {
        "setup-trekkie" = {
          wantedBy = [ "multi-user.target" ];
          script = ''
            mkdir -p /var/lib/trekkie
            chmod 755 /var/lib/trekkie
            chown ${config.systemd.services.trekkie.serviceConfig.User} /var/lib/trekkie
            chgrp ${config.users.groups.dump-dvb-radio.name} /var/lib/trekkie
          '';

          serviceConfig = {
            Type = "oneshot";
          };
        };

        "trekkie" = {
          enable = true;
          wantedBy = [ "multi-user.target" "setup-trekkie.service" ];

          script = ''
            exec ${pkgs.trekkie}/bin/trekkie --api-host ${cfg.host} --port ${toString cfg.port}&
          '';

          environment = {
            "POSTGRES_PASSWORD_PATH" = "${cfg.database.passwordFile}";
            "RUST_LOG" = "${cfg.log_level}";
            "RUST_BACKTRACE" = if (cfg.log_level == "info") then "0" else "1";
            "POSTGRES_HOST" = "${cfg.database.host}";
            "POSTGRES_PORT" = "${toString cfg.database.port}";
            "SALT_PATH" = "${cfg.saltPath}";
          };

          serviceConfig = {
            Type = "forking";
            User = cfg.user;
            Restart = "always";
          };
        };
      };
    };

    # user accounts for systemd units
    users.users."${cfg.user}" = {
      name = "${cfg.user}";
      description = "This guy runs trekkie";
      isNormalUser = false;
      isSystemUser = true;
      group = cfg.group;
      uid = 1502;
      extraGroups = [ config.users.groups."dump-dvb-radio".name ];
    };
  };
}
