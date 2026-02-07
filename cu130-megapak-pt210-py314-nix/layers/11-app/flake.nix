{
  description = "Layer 11: Application Scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer10.url = "path:../10-performance";
  };

  outputs = { self, nixpkgs, layer10 }:
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

      # Import package modules for the final Python environment
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

      # Python with all packages
      pythonWithAllPackages = python.withPackages (ps: packageList.allUpToPerformance);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer11-app";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer10.packages.${system}.default;

          copyToRoot = pkgs.runCommand "app-scripts" {} ''
            mkdir -p $out/builder-scripts
            mkdir -p $out/runner-scripts
            mkdir -p $out/default-comfyui-bundle

            # Copy builder scripts
            ${pkgs.rsync}/bin/rsync -av ${../../builder-scripts}/ $out/builder-scripts/
            chmod +x $out/builder-scripts/*.sh

            # Copy runner scripts
            ${pkgs.rsync}/bin/rsync -av ${../../runner-scripts}/ $out/runner-scripts/
            chmod +x $out/runner-scripts/*.sh
          '';

          config = {
            Env = [
              "PYTHON=${pythonWithAllPackages}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithAllPackages}/bin"
            ];
          };
        };
      };
    };
}
