{
  description = "Layer 7: pak5 - Extended Libraries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer06.url = "path:../06-cupy";
  };

  outputs = { self, nixpkgs, layer06 }:
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

      # Import package list helper
      packageList = import ../../package-lists.nix {
        inherit python;
        ps = python.pkgs;
        inherit torchPackages pak3Packages pak5Packages;
      };

      # Python with all packages up to pak5
      pythonWithPak5 = python.withPackages (ps: packageList.allUpToPak5);

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer07-pak5";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer06.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "pak5-env";
            paths = [ pythonWithPak5 ];
          };

          config = {
            Env = [
              "PYTHON=${pythonWithPak5}/bin/python3"
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${pythonWithPak5}/bin"
            ];
          };
        };
      };
    };
}
