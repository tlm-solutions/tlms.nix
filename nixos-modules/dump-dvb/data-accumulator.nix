{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.services.dataAccumulator;
in
{
  options.dump-dvb.services.dataAccumulator = with lib; {
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
      type = type.int;
      default = 8080;
      description = ''
        To which port should data-accumulator bind.
      '';
    };
    DBHost = mkOption {
      type = type.str;
      default = "127.0.0.1";
      description = ''
        Database host
      '';
    };
    DBPort = mkOption {
      type = type.int;
      default = "5354";
      description = ''
        Database port
      '';
    };
    DBPasswordFile = mkOption {
      type = type.either type.str type.path;
      default = "";
    };
    user = mkOption {
      type = types.str;
      default = "data-accumulator";
    };
    group = mkOption {
      type = types.str;
      default = "data-accumulator";
    };
  };

  # TODO: nice assertions for everything, Or just let the pkgs deal with that?
  config = lib.mkIf cfg.enable {
    systemd = {
      services = {
        "data-accumulator" = {
          enable = true;
          wantedBy = [ "multi-user.target" ];

          script = ''
            export POSTGRES_PASSWORD=$(cat ${config.sops.secrets.postgres_password_dvbdump.path})
            exec ${pkgs.data-accumulator}/bin/data-accumulator --host ${cfg.host} --port ${toString cfg.port}&
          '';

          environment = {
            "GRPC_HOST_1" = "http://127.0.0.1:50051";
            "GRPC_HOST_2" = "http://127.0.0.1:50051";
            "POSTGRES_HOST" = "${cfg.DBHost}";
            "POSTGRES_PORT" = "${toString cfg.DBPort}";
          };
          serviceConfig = {
            Type = "forking";
            User = "data-accumulator";
            Restart = "always";
          };
        };
      };
    };

    # user accounts for systemd units
    users.users."${cfg.user}" = {
      name = "${cfg.user}";
      description = "";
      isNormalUser = false;
      isSystemUser = true;
      group = cfg.group;
    };
  };
}
