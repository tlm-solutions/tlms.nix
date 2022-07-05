{ pkgs, config, ... }:
{
  options.dumpDVB.api = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    GRPCHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    GRPCPort = mkOption {
      type = types.int;
      defalut = 50051;
    };
    port = mkOption {
      type = types.int;
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
  };
  config = mkIf cfg.enable {
    systemd = {
      services = {
        "dvb-api" = {
          enable = true;
          wantedBy = [ "multi-user.target" ];

          script = "exec ${pkgs.dvb-api}/bin/dvb-api &";

          environment = {
            "GRPC_HOST" = "${cfg.GRPCHost}:${toString cfg.GRPCPort}";
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
      isSystemUser = true;
      extraGroups = [ ];
    };
  };
}
