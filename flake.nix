{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    utils = { url = "github:numtide/flake-utils"; };

    gnuradio-decoder = {
      url = "github:tlm-solutions/gnuradio-decoder";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    data-accumulator = {
      url = "github:tlm-solutions/data-accumulator";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
    };

    dvb-api = {
      url = "github:tlm-solutions/dvb-api";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
    };

    funnel = {
      url = "github:tlm-solutions/funnel";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    windshield = {
      url = "github:tlm-solutions/windshield";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    wartrammer = {
      url = "github:tlm-solutions/wartrammer-40k";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
    };

    click = {
      url = "github:tlm-solutions/click";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };

    stops = {
      url = "github:tlm-solutions/stop-names";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.utils.follows = "utils";
    };

    tlms-rs = {
      url = "github:tlm-solutions/tlms.rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = inputs@{ self, click, data-accumulator
    ,  dvb-api, funnel, nixpkgs, gnuradio-decoder, wartrammer
    , windshield, stops, tlms-rs, ... }:
    let
      system =
        "x86_64-linux"; # builtins.currentSystem doesn't work here apparently
    in {
      # composes all of our overlays into one
      overlays.default = nixpkgs.lib.composeManyExtensions [
        click.overlays.default
        data-accumulator.overlays.default
        dvb-api.overlays.default
        funnel.overlays.default
        gnuradio-decoder.overlays.default
        stops.overlays.default
        wartrammer.overlays.default
        windshield.overlays.default
      ];

      nixosModules = {
        TLMS = import ./nixos-modules/TLMS self;
        disk-module = import ./nixos-modules/disk-module;
        default = self.nixosModules.TLMS;
      };

      packages.${system}."run-database-migration" =
        tlms-rs.packages.${system}.run-migration;
    };
}
