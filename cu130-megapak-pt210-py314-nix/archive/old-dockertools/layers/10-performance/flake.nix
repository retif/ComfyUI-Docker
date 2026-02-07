{
  description = "Layer 10: Performance Libraries (flash-attn, sageattention, nunchaku)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer09.url = "path:../09-sam";
  };

  outputs = { self, nixpkgs, layer09 }:
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

      # Python with all packages including performance libs
      pythonWithPerformance = python.withPackages (ps: packageList.allUpToPerformance);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer10-performance";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer09.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "performance-env";
            paths = [ pythonWithPerformance ];
          };

          config = {
            Env = [
              "PYTHON=${pythonWithPerformance}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithPerformance}/bin"
            ];
          };
        };
      };
    };
}
