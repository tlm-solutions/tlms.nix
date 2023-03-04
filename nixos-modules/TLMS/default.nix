self:
{
  imports = [
    ./api.nix
    ./binary-cache.nix
    ./data-accumulator.nix
    ./funnel.nix
    ./gnuradio.nix
    ./json.nix
    ./wartrammer.nix
  ];

  nixpkgs.overlays = [
    self.overlays.default
  ];
}
