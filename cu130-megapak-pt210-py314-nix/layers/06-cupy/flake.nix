{
  description = "Layer 6: CuPy CUDA 13.x";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer05.url = "path:../05-pak3";
  };

  outputs = { self, nixpkgs, layer05 }:
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

      # Import all previous packages
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

      # Python with PyTorch + pak3 + cupy
      pythonWithCupy = python.withPackages (ps: with ps; [
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

        # CuPy
        torchPackages.cupy-cuda13x
      ]);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer06-cupy";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer05.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "cupy-env";
            paths = [ pythonWithCupy ];
          };

          config = {
            Env = [
              "PYTHON=${pythonWithCupy}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithCupy}/bin"
            ];
          };
        };
      };
    };
}
