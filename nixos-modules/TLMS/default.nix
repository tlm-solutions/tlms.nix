self:
{
  imports = [
    ./api.nix
    ./binary-cache.nix
    ./datacare.nix
    ./data-accumulator.nix
    ./funnel.nix
    ./gnuradio.nix
    ./json.nix
    ./telegram-decoder.nix
    ./telegram-decoder.nix
    ./wartrammer.nix
  ];

  nixpkgs.overlays = [
    self.overlays.default
  ];
}
