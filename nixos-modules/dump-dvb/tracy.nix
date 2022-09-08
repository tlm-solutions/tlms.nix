{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.dataAccumulator;
in
{
  options.dump-dvb.tracy = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''Wether to enable tracy service'';
    };
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = ''
        To which IP tracy should bind.
      '';
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = ''
        To which port should tracy bind.
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
      default = "tracy";
    };
    group = mkOption {
      type = types.str;
      default = "tracy";
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
        "tracy"
      ];
      gid = 1501;
    };

    systemd = {
      services = {
        "setup-tracy" = {
          wantedBy = [ "multi-user.target" ];
          script = ''
            mkdir -p /var/lib/tracy
            chmod 755 /var/lib/tracy
            chown ${config.systemd.services.tracy.serviceConfig.User} /var/lib/tracy
            chgrp ${config.users.groups.dump-dvb-radio.name} /var/lib/tracy
          '';

          serviceConfig = {
            Type = "oneshot";
          };
        };

        "tracy" = {
          enable = true;
          wantedBy = [ "multi-user.target" "setup-tracy.service" ];

          script = ''
            exec ${pkgs.tracy}/bin/tracy --host ${cfg.host} --port ${toString cfg.port}&
          '';

          environment = {
            "POSTGRES_PASSWORD_PATH" = "${cfg.database.passwordFile}";
            "RUST_LOG" = "${cfg.log_level}";
            "RUST_BACKTRACE" = if (cfg.log_level == "info") then "0" else "1";
            "POSTGRES_HOST" = "${cfg.database.host}";
            "POSTGRES_PORT" = "${toString cfg.database.port}";
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
      description = "This guy runs tracy";
      isNormalUser = false;
      isSystemUser = true;
      group = cfg.group;
      uid = 1501;
      extraGroups = [ config.users.groups."dump-dvb-radio".name ];
    };
  };
}
