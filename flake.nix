{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;

    radio-conf = {
      url = github:dump-dvb/radio-conf;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    data-accumulator = {
      url = github:dump-dvb/data-accumulator;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    decode-server = {
      url = github:dump-dvb/decode-server;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dvb-api = {
      url = github:dump-dvb/dvb-api;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    funnel = {
      url = github:dump-dvb/funnel;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    windshield = {
      url = github:dump-dvb/windshield;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    docs = {
      url = github:dump-dvb/documentation;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wartrammer = {
      url = github:dump-dvb/wartrammer-40k;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    click = {
      url = github:dump-dvb/click;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clicky-bunty-server = {
      url = github:dump-dvb/clicky-bunty-server;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stops = {
      url = github:dump-dvb/stop-names;
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ self
    , click
    , clicky-bunty-server
    , data-accumulator
    , decode-server
    , docs
    , dvb-api
    , funnel
    , nixpkgs
    , radio-conf
    , wartrammer
    , windshield
    , stops
    , ...
    }:
    {
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
    };
}
