{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.dataAccumulator;
in
{
  options.dump-dvb.dataAccumulator = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''Wether to enable data accumulator service'';
    };
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = ''
        To which IP data-accumulator should bind.
      '';
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = ''
        To which port should data-accumulator bind.
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
      default = "data-accumulator";
    };
    group = mkOption {
      type = types.str;
      default = "data-accumulator";
    };
    log_level = mkOption {
      type = types.str;
      default = "info";
    };
    GRPC = mkOption {
      type = types.listOf
        (types.submodule {
          options.schema = mkOption {
            type = types.enum [ "http" "https" ];
            default = "http";
            description = ''
              schema to connect to GRPC
            '';
          };
          options.name = mkOption {
            type = types.str;
            default = "";
            description = ''
              GRPC name
            '';
          };
          options.host = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = ''
              GRPC: schema://hostname
            '';
          };
          options.port = mkOption {
            type = types.port;
            default = 50051;
            description = ''
              GRPC port
            '';
          };
        });
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.dump-dvb-radio = {
      name = "dump-dvb-radio";
      members = [
        "wartrammer"
        "data-accumulator"
      ];
      gid = 1501;
    };

    systemd = {
      services = {
        "setup-data-accumulator" = {
          wantedBy = [ "multi-user.target" ];
          script = ''
            mkdir -p /var/lib/data-accumulator
            chmod 755 /var/lib/data-accumulator
            chown ${config.systemd.services.data-accumulator.serviceConfig.User} /var/lib/data-accumulator
            chgrp ${config.users.groups.dump-dvb-radio.name} /var/lib/data-accumulator
          '';

          serviceConfig = {
            Type = "oneshot";
          };
        };

        "data-accumulator" = {
          enable = true;
          wantedBy = [ "multi-user.target" "setup-data-accumulator.service" ];

          script = ''
            exec ${pkgs.data-accumulator}/bin/data-accumulator --host ${cfg.host} --port ${toString cfg.port}&
          '';

          environment = {
            "POSTGRES_PASSWORD_PATH" = "${cfg.database.passwordFile}";
            "RUST_LOG" = "${cfg.log_level}";
            "RUST_BACKTRACE" = if (cfg.log_level == "info") then "0" else "1";
            "POSTGRES_HOST" = "${cfg.database.host}";
            "POSTGRES_PORT" = "${toString cfg.database.port}";
          } // (lib.foldl
            (x: y:
              lib.mergeAttrs x { "GRPC_HOST_${y.name}" = "${y.schema}://${y.host}:${toString y.port}"; })
            { }
            cfg.GRPC);

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
      description = "This guy runs data-accumulator";
      isNormalUser = false;
      isSystemUser = true;
      group = cfg.group;
      uid = 1501;
      extraGroups = [ config.users.groups."dump-dvb-radio".name ];
    };
  };
}
