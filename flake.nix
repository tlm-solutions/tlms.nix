{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils = { url = "github:numtide/flake-utils"; };

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
    };

    decode-server = {
      url = "github:dump-dvb/decode-server";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
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

    datacare = {
      url = "github:dump-dvb/datacare";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
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

    trekkie = {
      url = "github:dump-dvb/trekkie";
      inputs.naersk.follows = "naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, click, datacare, data-accumulator
    , decode-server, dvb-api, funnel, nixpkgs, radio-conf, wartrammer
    , windshield, stops, dump-dvb-rs, trekkie, ... }:
    let
      system =
        "x86_64-linux"; # builtins.currentSystem doesn't work here apparently
    in {
      # composes all of our overlays into one
      overlays.default = nixpkgs.lib.composeManyExtensions [
        click.overlays.default
        datacare.overlays.default
        data-accumulator.overlays.default
        decode-server.overlays.default
        dvb-api.overlays.default
        funnel.overlays.default
        radio-conf.overlays.default
        stops.overlays.default
        wartrammer.overlays.default
        windshield.overlays.default
        trekkie.overlays.default
      ];

      nixosModules = {
        dump-dvb = import ./nixos-modules/dump-dvb self;
        disk-module = import ./nixos-modules/disk-module;
        default = self.nixosModules.dump-dvb;
      };

      packages.${system}."run-database-migration" =
        dump-dvb-rs.packages.${system}.run-migration;
    };
}
