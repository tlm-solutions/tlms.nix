{ pkgs, config, lib, ... }:
let
  cfg = config.TLMS.datacare;
in
{
  options.TLMS.datacare = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Wether to enable datacare: TLMS colorful and clicky registration tool
      '';
    };
    rustBacktrace = mkOption {
      type = types.str;
      default = "FULL";
      description = ''rust backtrace'';
    };
    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''host of datacare'';
    };
    port = mkOption {
      type = types.port;
      default = 5070;
      description = ''port of datacare'';
    };
    saltFile = mkOption {
      type = types.either types.str types.path;
      default = "";
      description = ''file from where the salt can be read'';
    };
    postgresPasswordFile = mkOption {
      type = types.either types.str types.path;
      default = "";
      description = ''file from where the postgres password can be read'';
    };
    postgresHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = ''file from where the postgres password can be read'';
    };
    postgresPort = mkOption {
      type = types.int;
      default = 5070;
      description = ''port of the postgres database'';
    };
    user = mkOption {
      type = types.str;
      default = "datacare";
      description = ''systemd user'';
    };
    group = mkOption {
      type = types.str;
      default = "datacare";
      description = ''group of systemd user'';
    };
    log_level = mkOption {
      type = types.str;
      default = "info";
      description = ''log level of the application'';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.datacare ];
    systemd.services = {
      "datacare" = {
        enable = true;

        description = "dvbdump managment service";
        wantedBy = [ "multi-user.target" ];

        script = ''
          exec ${pkgs.datacare}/bin/datacare --host ${cfg.host} --port ${toString cfg.port}&
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
          User = "datacare";
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
