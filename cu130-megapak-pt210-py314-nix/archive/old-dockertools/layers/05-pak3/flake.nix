{
  description = "Layer 5: pak3 - Core ML Essentials";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer04.url = "path:../04-pytorch";
  };

  outputs = { self, nixpkgs, layer04 }:
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

      # Import custom packages
      torchPackages = pkgs.callPackage ../../custom-packages.nix {
        inherit python cudaPackages;
        pythonPackages = python.pkgs;
        buildPythonPackage = python.pkgs.buildPythonPackage;
        fetchurl = pkgs.fetchurl;
      };

      pak3Packages = pkgs.callPackage ../../pak3.nix {
        inherit python;
        pythonPackages = python.pkgs;
        buildPythonPackage = python.pkgs.buildPythonPackage;
        fetchurl = pkgs.fetchurl;
      };

      # Python with PyTorch + pak3
      pythonWithPak3 = python.withPackages (ps: with ps; [
        pip setuptools wheel packaging build
        # PyTorch
        torchPackages.torch
        torchvision
        torchPackages.torchaudio

        # Core ML frameworks
        pak3Packages.accelerate
        pak3Packages.diffusers
        huggingface-hub
        transformers

        # Scientific computing
        numpy scipy pillow imageio scikit-learn scikit-image matplotlib pandas

        # Computer vision
        opencv4
        pak3Packages.opencv-contrib-python
        pak3Packages.opencv-contrib-python-headless
        pak3Packages.kornia

        # ML utilities
        pak3Packages.timm
        pak3Packages.torchmetrics
        pak3Packages.compel
        pak3Packages.lark

        # Data formats
        pyyaml omegaconf onnx

        # System utilities
        joblib psutil tqdm regex
        pak3Packages.nvidia-ml-py

        # Additional
        pak3Packages.ftfy
      ]);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer05-pak3";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer04.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "pak3-env";
            paths = [ pythonWithPak3 ];
          };

          config = {
            Env = [
              "PYTHON=${pythonWithPak3}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithPak3}/bin"
            ];
          };
        };
      };
    };
}
