{
  description = "Layer 12: ComfyUI Bundle (Final)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer11.url = "path:../11-app";
  };

  outputs = { self, nixpkgs, layer11 }:
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
        # Final layered image
        default = pkgs.dockerTools.streamLayeredImage {
          name = "comfyui-boot";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer11.packages.${system}.default;

          contents = [ pythonWithAllPackages ];

          config = {
            Cmd = [ "${pkgs.bash}/bin/bash" "/runner-scripts/entrypoint.sh" ];
            WorkingDir = "/root";
            ExposedPorts = {
              "8188/tcp" = {};
            };
            Env = [
              "CLI_ARGS="
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithAllPackages}/bin"
              "PYTHON=${pythonWithAllPackages}/bin/python3"
            ];
            Volumes = {
              "/root" = {};
            };
          };
        };
      };
    };
}
