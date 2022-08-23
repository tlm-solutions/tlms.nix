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
              "/api/" = {
                proxyPass = "http://127.0.0.1:${toString cfg.port}";
              };
              "/" = {
                root = "${pkgs.wartrammer-frontend}/bin/";
                index = "index.html";
              };
              "/result/" = {
                root = "/var/lib/wartrammer-40k/";
                extraConfig = ''
                  autoindex on
                '';
              };
              "/data/" = {
                root = "/var/lib/data-accumulator/";
                extraConfig = ''
                  autoindex on
                '';
              };
            };
          };
        };
      };
    };

    systemd.services."setup-wartrammer" = {
      wantedBy = [ "multi-user.target" "data-accumulator.service" ];
      script = ''
        mkdir -p /var/lib/wartrammer-40k
        chmod 755 /var/lib/wartrammer-40k
        chown ${config.systemd.services.wartrammer.serviceConfig.User} /var/lib/wartrammer-40k
      '';

      serviceConfig = {
        Type = "oneshot";
      };
    };

    systemd.services."wartrammer" = {
      enable = true;
      wantedBy = [ "multi-user.target" "setup-wartrammer.service"];
      script = ''
        exec ${pkgs.wartrammer-backend}/bin/wartrammer-40k --port ${toString cfg.port} &
      '';

      environment = {
        "PATH_DATA" = "/var/lib/wartrammer-40k/times.json";
        "IN_DATA" = "/var/lib/data-accumulator/formatted.csv";
        "OUT_DATA" = "/var/lib/wartrammer-40k/out.csv";
      };

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
