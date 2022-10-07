self:
{
  imports = [
    ./api.nix
    ./binary-cache.nix
    ./clicky-bunty.nix
    ./data-accumulator.nix
    ./funnel.nix
    ./gnuradio.nix
    ./json.nix
    ./telegram-decoder.nix
    ./telegram-decoder.nix
    ./wartrammer.nix
    ./trekkie.nix
  ];

  nixpkgs.overlays = [
    self.overlays.default
  ];
}
