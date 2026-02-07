{
  description = "Layer 2: Python 3.14 + System Tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer01.url = "path:../01-base-cuda";
  };

  outputs = { self, nixpkgs, layer01 }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };

      python = pkgs.python314;

      # Python with basic build tools only
      pythonBase = python.withPackages (ps: with ps; [
        pip setuptools wheel packaging build
      ]);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer02-python-tools";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer01.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "python-tools-env";
            paths = [
              pythonBase
              pkgs.aria2
              pkgs.vim
              pkgs.fish
            ];
          };

          config = {
            Env = [
              "PYTHON=${pythonBase}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonBase}/bin"
            ];
          };
        };
      };
    };
}
