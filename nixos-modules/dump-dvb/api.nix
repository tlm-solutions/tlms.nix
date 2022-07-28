{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.api;
in
{
  options.dump-dvb.api = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    GRPC.host = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    GRPC.port = mkOption {
      type = types.int;
      default = 50051;
    };
    port = mkOption {
      type = types.port;
      default = 9001;
    };
    graphFile = mkOption {
      type = types.either types.path types.str;
      default = "";
    };
    stopsFile = mkOption {
      type = types.either types.path types.str;
      default = "";
    };
    user = mkOption {
      type = types.str;
      default = "dvb-api";
      description = "as which user dvb-api should run";
    };
    group = mkOption {
      type = types.str;
      default = "dvb-api";
      description = "as which group dvb-api should run";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd = {
      services = {
        "dvb-api" = {
          enable = true;
          wantedBy = [ "multi-user.target" ];

          script = "exec ${pkgs.dvb-api}/bin/dvb-api &";

          environment = {
            "GRPC_HOST" = "${cfg.GRPC.host}:${toString cfg.GRPC.port}";
            "HTTP_PORT" = "${toString cfg.port}";
            "GRAPH_FILE" = "${cfg.graphFile}";
            "STOPS_FILE" = "${cfg.stopsFile}";
          };

          serviceConfig = {
            Type = "forking";
            User = "${cfg.user}";
            Restart = "always";
          };
        };
      };
    };

    # user accounts for systemd units
    users.users."${cfg.user}" = {
      name = "${cfg.user}";
      description = "public dvb api service";
      group = "${cfg.group}";
      isSystemUser = true;
      extraGroups = [ ];
    };
  };
}
