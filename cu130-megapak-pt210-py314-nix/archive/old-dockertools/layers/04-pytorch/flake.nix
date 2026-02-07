{
  description = "Layer 4: PyTorch 2.10.0 + CUDA 13.0";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer03.url = "path:../03-gcc15";
  };

  outputs = { self, nixpkgs, layer03 }:
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
      cudaPackages = pkgs.cudaPackages_13_0;

      # Import PyTorch packages
      torchPackages = pkgs.callPackage ../../custom-packages.nix {
        inherit python cudaPackages;
        pythonPackages = python.pkgs;
        buildPythonPackage = python.pkgs.buildPythonPackage;
        fetchurl = pkgs.fetchurl;
      };

      # Python with PyTorch
      pythonWithPyTorch = python.withPackages (ps: with ps; [
        pip setuptools wheel packaging build
        # PyTorch
        torchPackages.torch
        torchvision
        torchPackages.torchaudio
      ]);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer04-pytorch";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer03.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "pytorch-env";
            paths = [ pythonWithPyTorch ];
          };

          config = {
            Env = [
              "PYTHON=${pythonWithPyTorch}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithPyTorch}/bin"
            ];
          };
        };
      };
    };
}
