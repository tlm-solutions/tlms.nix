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
    CSVFile = mkOption {
      type = types.str;
      default = "";
      description = ''
        If set, to which CSV files to write captured telegrams
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
          options.name = mkOption {
            type = types.str;
            default = "";
            description = ''
              GRPC name
            '';
          };
          options.host = mkOption {
            type = types.str;
            default = "http://127.0.0.1";
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
    systemd = {
      services = {
        "data-accumulator" = {
          enable = true;
          wantedBy = [ "multi-user.target" ];

          script = ''
            export POSTGRES_TELEGRAMS_PASSWORD=$(cat ${cfg.DB.telegramsPasswordFile})
            export POSTGRES_DVBDUMP_PASSWORD=$(cat ${cfg.DB.dvbPasswordFile})
            exec ${pkgs.data-accumulator}/bin/data-accumulator --host ${cfg.host} --port ${toString cfg.port}&
          '';

          environment = {
            "POSTGRES_HOST" = "${cfg.DB.host}";
            "POSTGRES_PORT" = "${toString cfg.DB.port}";
            "DATABASE_BACKEND" = "${cfg.DB.backend}";
            "CSV_FILE" = "${cfg.CSVFile}";
          } // (lib.foldl
            (x: y:
              lib.mergeAttrs x { "GRPC_HOST_${y.name}" = "${y.host}:${toString y.port}"; })
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
    };
  };
}
