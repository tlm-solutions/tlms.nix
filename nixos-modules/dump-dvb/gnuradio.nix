{ pkgs, config, lib, ... }:
let
  cfg = config.dump-dvb.gnuradio;
in
{
  options.dump-dvb.gnuradio = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''Wether to enable dump-dvb gnuradio reciever'';
    };
    device = mkOption {
      type = types.str;
      default = "";
      example = "hackrf=0";
      description = ''Device string to pass to gnuradio'';
    };
    frequency = mkOption {
      type = types.int;
      default = 170795000;
      description = ''Frequency to tune radio to'';
    };
    offset = mkOption {
      type = types.int;
      default = 19550;
      description = ''Offset of the signal from center frequency'';
    };
    RF = mkOption {
      type = types.int;
      default = 14;
    };
    IF = mkOption {
      type = types.int;
      default = 32;
    };
    BB = mkOption {
      type = types.int;
      default = 42;
    };
    user = mkOption {
      type = types.str;
      default = "gnuradio";
      description = "as which user gnuradio should run";
    };
    group = mkOption {
      type = types.str;
      default = "gnuradio";
      description = "as which group gnuradio should run";
    };
  };

  config = lib.mkIf cfg.enable {

    hardware = {
      hackrf.enable = true;
      rtl-sdr.enable = true;
    };

    environment.systemPackages = [ pkgs.gnuradio-decoder ];

    systemd.services."gnuradio" = {
      enable = true;
      wantedBy = [ "multi-user.target" ];

      script = "exec ${pkgs.gnuradio-decoder}/bin/gnuradio-decoder-cpp ${toString cfg.frequency} ${toString cfg.offset} ${toString cfg.RF} ${toString cfg.IF} ${toString cfg.BB} ${cfg.device} &";

      serviceConfig = {
        Type = "forking";
        User = cfg.user;
        Restart = "on-failure";
        StartLimitBurst = "2";
        StartLimitIntervalSec = "150s";
      };
    };

    users.groups."${cfg.group}" = { };
    users.users."${cfg.user}" = {
      name = cfg.user;
      description = "gnu radio service user";
      isNormalUser = true;
      group = cfg.group;
      extraGroups = [ "plugdev" ];
    };

    security.wrappers.gnuradio-decode = {
      owner = cfg.user;
      group = "users";
      capabilities = "cap_sys_nice+eip";
      source = "${pkgs.gnuradio-decoder}/bin/gnuradio-decoder-cpp";
    };

  };
}

