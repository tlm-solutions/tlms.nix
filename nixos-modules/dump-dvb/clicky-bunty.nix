{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.clickyBuntyServer;
in
{
  options.dump-dvb.clickyBuntyServer = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Wether to enable clicky-bunty-server: dump-dvb colorful and clicky registration tool
      '';
    };
    rustBacktrace = mkOption {
      type = types.str;
      default = "FULL";
      description = ''rust backtrace''
    };
    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''host of clicky bunty''
    };
    port = mkOption {
      type = types.port;
      default = 5070;
      description = ''port of clicky bunty''
    };
    saltFile = mkOption {
      type = types.either types.str types.path;
      default = "";
      description = ''file from where the salt can be read''
    };
    postgresPasswordFile = mkOption {
      type = types.either types.str types.path;
      default = "";
      description = ''file from where the postgres password can be read''
    };
    postgresHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''file from where the postgres password can be read''
    };
    postgresPort = mkOption {
      type = types.int;
      default = 5070;
      description = ''port of the postgres database''
    };
    user = mkOption {
      type = types.str;
      default = "clicky-bunty-server";
      description = ''systemd user''
    };
    group = mkOption {
      type = types.str;
      default = "clicky-bunty-server";
      description = ''group of systemd user''
    };
    log_level = mkOption {
      type = types.str;
      default = "info";
      description = ''log level of the application''
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.clicky-bunty-server ];
    systemd.services = {
      "clicky-bunty-server" = {
        enable = true;

        description = "dvbdump managment service";
        wantedBy = [ "multi-user.target" ];

        script = ''
          exec ${pkgs.clicky-bunty-server}/bin/clicky-bunty-server --host ${cfg.host} --port ${toString cfg.port}&
        '';

        environment = {
          "RUST_BACKTRACE" = "${cfg.rustBacktrace}";
          "SALT_PATH" = "${cfg.saltFile}";
          "POSTGRES_PASSWORD_PATH" = "${cfg.postgresPasswordFile}";
          "RUST_LOG" = "${cfg.log_level}";
          "POSTGRES_HOST" = "${cfg.postgresHost}";
          "POSTGRES_PORT" = "${toString cfg.postgresPort}";
        };

        serviceConfig = {
          Type = "forking";
          User = "clicky-bunty-server";
          Restart = "always";
        };
      };
    };

    # user accounts for systemd units
    users.users."${cfg.user}" = {
      name = cfg.user;
      isSystemUser = true;
      group = cfg.group;
    };
  };
}
