{ self, config, pkgs, lib, ... }:
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
                # wartrammer frontend needs to be build on x86_64-linux, but the output is generic html/js
                root = self.inputs.wartrammer.packages."x86_64-linux".wartrammer-frontend;
                index = "index.html";
              };
              "/wartrammer-40k/" = {
                root = "/var/lib/";
                extraConfig = ''
                  autoindex on;
                '';
              };
              "/formatted.csv" = {
                root = "/var/lib/data-accumulator/";
                extraConfig = ''
                  autoindex on;
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
      wantedBy = [ "multi-user.target" "setup-wartrammer.service" ];
      script = ''
        exec ${pkgs.wartrammer-backend}/bin/wartrammer-40k --port ${toString cfg.port} &
      '';

      environment = {
        "PATH_DATA" = "/var/lib/wartrammer-40k/times.json";
        "IN_DATA" = "/var/lib/wartrammer-40k/formatted.csv";
        "OUT_DATA" = "/var/lib/wartrammer-40k/out.csv";
        "CSV_FILE_R09" = "/var/lib/wartrammer-40k/formatted.csv";
        "CSV_FILE_RAW" = "/var/lib/wartrammer-40k/raw.csv";
        "RUST_LOG" = "debug";
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
