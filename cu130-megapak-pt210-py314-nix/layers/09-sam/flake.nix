{
  description = "Layer 9: SAM-2 & SAM-3 (Placeholder - TODO)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer08.url = "path:../08-pak7";
  };

  outputs = { self, nixpkgs, layer08 }:
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

      # Import package modules
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

      pak5Packages = pkgs.callPackage ../../pak5.nix {
        inherit python;
        pythonPackages = python.pkgs;
        buildPythonPackage = python.pkgs.buildPythonPackage;
      };

      pak7Packages = pkgs.callPackage ../../pak7.nix {
        inherit python;
        pythonPackages = python.pkgs;
        buildPythonPackage = python.pkgs.buildPythonPackage;
        fetchFromGitHub = pkgs.fetchFromGitHub;
      };

      # Import package list helper
      packageList = import ../../package-lists.nix {
        inherit python torchPackages pak3Packages pak5Packages pak7Packages;
        ps = python.pkgs;
      };

      # Python with all packages up to pak7 (SAM not yet implemented)
      # TODO: Add SAM-2 and SAM-3 packages when implemented
      pythonWithSAM = python.withPackages (ps: packageList.allUpToPak7);

    in {
      packages.${system} = {
        # Placeholder layer - just passes through for now
        # TODO: Build SAM-2 from https://github.com/facebookresearch/sam2
        # TODO: Build SAM-3 from https://github.com/facebookresearch/sam3
        # Both require special build flags (SAM2_BUILD_CUDA=1, --no-deps, --no-build-isolation)
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer09-sam";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer08.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "sam-env";
            paths = [ pythonWithSAM ];
          };

          config = {
            Env = [
              "PYTHON=${pythonWithSAM}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithSAM}/bin"
            ];
          };
        };
      };
    };
}
