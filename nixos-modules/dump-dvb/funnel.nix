{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.funnel;
in
{
  options.dump-dvb.funnel = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    GRPC = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
      };
      port = mkOption {
        type = types.port;
        default = 50052;
      };
    };
    defaultWebsocket = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
      };
      port = mkOption {
        type = types.port;
        default = 9002;
      };
    };
    user = mkOption {
      type = types.str;
      default = "funnel";
    };
    group = mkOption {
      type = types.str;
      default = "funnel";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services = {
        "funnel" = {
          enable = true;
          wantedBy = [ "multi-user.target" ];

          script = "exec ${pkgs.funnel}/bin/funnel &";

          environment = {
            "GRPC_PORT" = "${cfg.GRPC.port}";
            "WEBSOCKET_PORT" = "${cfg.defaultWebsocket.port}";
            #"GRPC_HOST" = "${cfg.GRPC.host}:${toString cfg.GRPC.port}";
            #"DEFAULT_WEBSOCKET_HOST" = "${cfg.defaultWebsocket.host}:${toString cfg.defaultWebsocket.port}";
            "GRAPH_FILE" = "${config.dump-dvb.graphJson}";
            "STOPS_FILE" = "${config.dump-dvb.stopsJson}";
          };

          serviceConfig = {
            Type = "forking";
            User = "${cfg.user}";
            Restart = "always";
          };
        };
      };
    };

    users.users = {
      "${cfg.user}" = {
        name = "${cfg.user}";
        description = "public websocket service user";
        isSystemUser = true;
        group = "${cfg.group}";
        extraGroups = [ ];
      };
    };
  };
}
