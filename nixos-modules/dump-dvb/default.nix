self:
{ pkgs, ... }: {
  imports = [
    ./gnuradio.nix
    ./data-accumulator.nix
    ./telegram-decoder.nix
    ./binary-cache.nix
    ./clicky-bunty.nix
    ./telegram-decoder.nix
  ];

  nixpkgs.overlays = [
    self.overlays.default
  ];
}
