{ config, lib, pkgs, ... }:
let
  cfg = config.dump-dvb.telegramDecoder;
in
{
  options.dump-dvb.telegramDecoder = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''Wether to enable dump-dvb telegram-decoder'';
    };
    server = mkOption {
      type = types.listOf types.str;
      default = [ "https://dump.dvb.solutions/" ];
      description = ''URL of the dump-dvb websocket'';
    };
    configFile = mkOption {
      type = types.either types.str types.path;
      default = "/etc/telegram-decoder/settings.json";
      description = ''Path to telegram-decoder config'';
    };
    authTokenFile = mkOption {
      type = types.either types.str types.path;
      default = "";
      description = ''Path to telegram-decoder auth token'';
    };
  };


  config = lib.mkIf cfg.enable {

    environment.systemPackages = [ pkgs.telegram-decoder ];

    users.groups.telegram-decoder = { };

    users.users.telegram-decoder = {
      name = "telegram-decoder";
      description = "gnu radio service user";
      group = "telegram-decoder";
      isSystemUser = true;
    };

    systemd.services."telegram-decoder" = {
      enable = true;
      wantedBy = [ "multi-user.target" ];

      script = "exec ${pkgs.telegram-decoder}/bin/telegram-decode --config ${cfg.configFile} --server ${(builtins.concatStringsSep " " cfg.server)} &";

      environment = {
        AUTHENTICATION_TOKEN_PATH = cfg.authTokenFile;
      };

      serviceConfig = {
        Type = "forking";
        User = "telegram-decoder";
        Restart = "on-failure";
        StartLimitBurst = "2";
        StartLimitIntervalSec = "150s";
      };
    };
  };
}
