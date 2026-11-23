# cc3dsfs Flake

## Usage:

flake.nix:
```nix
{
  inputs = {
    cc3dsfs = {
      url = "github:RealHypnoticOcelot/cc3dsfs-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  }
}
```

configuration.nix:
```nix
{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  cc3dsfsPkg = inputs.cc3dsfs.packages.${system}.default;
in {
  environment.systemPackages = [
    cc3dsfsPkg
  ];
}
```

## Building

To create a production version of your app:

```sh
nix build
```
You can preview the production build with `nix run`.