{ lib, pkgs, config, ... }:
with lib; {
  options.dump-dvb = {
    stopsJson = mkOption {
      type = types.str;
      default = "";
      description = "stops.json location";
    };
    graphJson = mkOption {
      type = types.str;
      default = "";
      description = "graph.json location";
    };
  };
}
