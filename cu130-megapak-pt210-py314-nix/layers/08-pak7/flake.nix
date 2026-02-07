{
  description = "Layer 8: pak7 - Face Analysis + Git Packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer07.url = "path:../07-pak5";
  };

  outputs = { self, nixpkgs, layer07 }:
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

      # Python with all packages up to pak7
      pythonWithPak7 = python.withPackages (ps: packageList.allUpToPak7);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer08-pak7";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer07.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "pak7-env";
            paths = [ pythonWithPak7 ];
          };

          config = {
            Env = [
              "PYTHON=${pythonWithPak7}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithPak7}/bin"
            ];
          };
        };
      };
    };
}
