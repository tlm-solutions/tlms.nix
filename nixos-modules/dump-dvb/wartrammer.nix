{ config, pkgs, lib, ... }:
let
  cfg = config.dump-dvb.wartrammer;
in
{
  options.dump-dvb.wartrammer = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Wether to enable wartrammer-40k
      '';
    };
    port = mkOption {
      type = types.port;
      default = 7680;
      description = ''
        On which port to expose wartrammer
      '';
    };
    user = mkOption {
      type = types.str;
      default = "wartrammer";
      description = ''
        As which user wartrammer should run
      '';
    };
    group = mkOption {
      type = types.str;
      default = "wartrammer";
      description = ''
        Which group wartrammer user is in
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    services = {
      nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts = {
          "wartrammer" = {
            locations = {
              "/" = {
                root = "${pkgs.wartrammer-frontend}/bin/";
                index = "index.html";
              };
              "/api" = {
                proxyPass = "http://127.0.0.1:${toString cfg.port}";
              };
            };
          };
        };
      };
    };

    systemd.services."wartrammer" = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      script = ''
        exec ${pkgs.wartrammer-backend}/bin/wartrammer-40k --port ${toString cfg.port} &
      '';
      serviceConfig = {
        Type = "forking";
        User = cfg.user;
        Restart = "on-failure";
        StartLimitBurst = "2";
        StartLimitIntervalSec = "150s";
      };
    };

    users.users."${cfg.user}" = {
      name = "${cfg.user}";
      group = "${cfg.group}";
      description = "guy that runs wartrammer-40k";
      isSystemUser = true;
    };
  };
}
