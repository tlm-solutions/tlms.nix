{ lib, pkgs, config, ... }:
with lib; {
  dump-dvb = {
    stopsJson = mkOption {
      type = types.path;
      default = "${pkgs.stops-json}/stops.json";
      description = "stops conig json";
    };
    dump-dvb.graphJson = mkOption {
      type = types.path;
      default = "${pkgs.graph-json}/graph.json";
      description = "graph json containing the network graphs";
    };
  };
}
