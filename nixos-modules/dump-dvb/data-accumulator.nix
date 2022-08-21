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
    R09CsvFile = mkOption {
      type = types.str;
      default = "";
      description = ''
        If set, to which CSV files to write captured R09 telegrams
      '';
    };
    RawFile = mkOption {
      type = types.str;
      default = "";
      description = ''
        If set, to which csv file to write captured unparsed telegrams
      '';
    };
    offline = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If set to true this will run in war tramming mode with out any authentication
      '';
    };

    DB = {
      backend = mkOption {
        type = types.enum [ "POSTGRES" "CSVFILE" ];
        default = "POSTGRES";
        description = ''
          Which database to use
        '';
      };
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
      telegramsPasswordFile = mkOption {
        type = types.either types.path types.string;
        default = "";
      };
      dvbPasswordFile = mkOption {
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
            chmod 744 /var/lib/data-accumulator
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
            export POSTGRES_TELEGRAMS_PASSWORD=$(cat ${cfg.DB.telegramsPasswordFile})
            export POSTGRES_DVBDUMP_PASSWORD=$(cat ${cfg.DB.dvbPasswordFile})
            exec ${pkgs.data-accumulator}/bin/data-accumulator --host ${cfg.host} --port ${toString cfg.port} ${if cfg.offline then "--offline" else ""}&
          '';

          environment = {
            "POSTGRES_HOST" = "${cfg.DB.host}";
            "POSTGRES_PORT" = "${toString cfg.DB.port}";
            "DATABASE_BACKEND" = "${cfg.DB.backend}";
            "CSV_FILE_R09" = "${cfg.R09CsvFile}";
            "CSV_FILE_RAW" = "${cfg.RawFile}";
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
      description = "This guy runs clicky-bunty-server";
      isNormalUser = false;
      isSystemUser = true;
      group = cfg.group;
      uid = 1501;
      extraGroups = [ config.users.groups."dump-dvb-radio".name ];
    };
  };
}
