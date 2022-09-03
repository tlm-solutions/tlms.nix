{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils = { url = "github:numtide/flake-utils"; };

    stops-no-flake = {
      url = "github:dump-dvb/stop-names";
      flake = false;
    };

    radio-conf = {
      url = "github:dump-dvb/radio-conf";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    data-accumulator = {
      url = "github:dump-dvb/data-accumulator";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
      inputs.stops.follows = "stops-no-flake";
    };

    decode-server = {
      url = "github:dump-dvb/decode-server";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
      inputs.stops.follows = "stops-no-flake";
    };

    dvb-api = {
      url = "github:dump-dvb/dvb-api";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
    };

    funnel = {
      url = "github:dump-dvb/funnel";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    windshield = {
      url = "github:dump-dvb/windshield";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    docs = {
      url = "github:dump-dvb/documentation";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wartrammer = {
      url = "github:dump-dvb/wartrammer-40k";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
    };

    click = {
      url = "github:dump-dvb/click";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    clicky-bunty-server = {
      url = "github:dump-dvb/clicky-bunty-server";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
      inputs.stops.follows = "stops-no-flake";
    };

    stops = {
      url = "github:dump-dvb/stop-names";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
    };

    dump-dvb-rs = {
      url = "github:dump-dvb/dump-dvb.rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, click, clicky-bunty-server, data-accumulator
    , decode-server, docs, dvb-api, funnel, nixpkgs, radio-conf, wartrammer
    , windshield, stops, dump-dvb-rs, ... }:
    let
      system =
        "x86_64-linux"; # builtins.currentSystem doesn't work here apparently
    in {
      # composes all of our overlays into one
      overlays.default = nixpkgs.lib.composeManyExtensions [
        click.overlays.default
        clicky-bunty-server.overlays.default
        data-accumulator.overlays.default
        decode-server.overlays.default
        docs.overlays.default
        dvb-api.overlays.default
        funnel.overlays.default
        radio-conf.overlays.default
        stops.overlays.default
        wartrammer.overlays.default
        windshield.overlays.default
      ];

      nixosModules = {
        dump-dvb = import ./nixos-modules/dump-dvb self;
        default = self.nixosModules.dump-dvb;
      };

      packages.${system}."run-database-migration" =
        dump-dvb-rs.packages.${system}.run-migration;
    };
}
