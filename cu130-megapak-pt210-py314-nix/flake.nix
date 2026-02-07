{
  description = "ComfyUI Docker - Pure Nix build with layered architecture";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Layer inputs
    layer01.url = "path:./layers/01-base-cuda";
    layer02.url = "path:./layers/02-python-tools";
    layer03.url = "path:./layers/03-gcc15";
    layer04.url = "path:./layers/04-pytorch";
    layer05.url = "path:./layers/05-pak3";
    layer06.url = "path:./layers/06-cupy";
    layer07.url = "path:./layers/07-pak5";
    layer08.url = "path:./layers/08-pak7";
    layer09.url = "path:./layers/09-sam";
    layer10.url = "path:./layers/10-performance";
    layer11.url = "path:./layers/11-app";
    layer12.url = "path:./layers/12-comfyui";
  };

  outputs = { self, nixpkgs, flake-utils, layer01, layer02, layer03, layer04, layer05, layer06, layer07, layer08, layer09, layer10, layer11, layer12 }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        python = pkgs.python314;
        cudaPackages = pkgs.cudaPackages_13_0;

        # Import modular Python package definitions
        pak3Packages = pkgs.callPackage ./pak3.nix {
          inherit python;
          pythonPackages = python.pkgs;
          buildPythonPackage = python.pkgs.buildPythonPackage;
          fetchurl = pkgs.fetchurl;
        };

        pak5Packages = pkgs.callPackage ./pak5.nix {
          inherit python;
          pythonPackages = python.pkgs;
          buildPythonPackage = python.pkgs.buildPythonPackage;
        };

        pak7Packages = pkgs.callPackage ./pak7.nix {
          inherit python;
          pythonPackages = python.pkgs;
          buildPythonPackage = python.pkgs.buildPythonPackage;
          fetchFromGitHub = pkgs.fetchFromGitHub;
        };

        customPackages = pkgs.callPackage ./custom-packages.nix {
          inherit python cudaPackages;
          pythonPackages = python.pkgs;
          buildPythonPackage = python.pkgs.buildPythonPackage;
          fetchurl = pkgs.fetchurl;
        };

        # Import package list helper
        packageList = import ./package-lists.nix {
          inherit python;
          ps = python.pkgs;
          torchPackages = customPackages;
          inherit pak3Packages pak5Packages pak7Packages;
        };

        # Python environment with all packages (for testing)
        pythonWithAllPackages = python.withPackages (ps: packageList.all);

      in {
        packages = {
          # Individual layers
          layer01-base-cuda = layer01.packages.${system}.default;
          layer02-python-tools = layer02.packages.${system}.default;
          layer03-gcc15 = layer03.packages.${system}.default;
          layer04-pytorch = layer04.packages.${system}.default;
          layer05-pak3 = layer05.packages.${system}.default;
          layer06-cupy = layer06.packages.${system}.default;
          layer07-pak5 = layer07.packages.${system}.default;
          layer08-pak7 = layer08.packages.${system}.default;
          layer09-sam = layer09.packages.${system}.default;
          layer10-performance = layer10.packages.${system}.default;
          layer11-app = layer11.packages.${system}.default;
          layer12-comfyui = layer12.packages.${system}.default;

          # Final image (default)
          comfyui = layer12.packages.${system}.default;
          default = layer12.packages.${system}.default;

          # Expose Python environment for debugging
          inherit pythonWithAllPackages;
        };

        # Apps for building layers
        apps = {
          # Build all layers incrementally
          build-all-layers = {
            type = "app";
            program = toString (pkgs.writeScript "build-all-layers" ''
              #!${pkgs.bash}/bin/bash
              set -e

              echo "Building Layer 01: Base + CUDA..."
              nix build .#layer01-base-cuda
              docker load < result

              echo "Building Layer 02: Python + Tools..."
              nix build .#layer02-python-tools
              docker load < result

              echo "Building Layer 03: GCC 15..."
              nix build .#layer03-gcc15
              docker load < result

              echo "Building Layer 04: PyTorch..."
              nix build .#layer04-pytorch
              docker load < result

              echo "Building Layer 05: pak3 Essentials..."
              nix build .#layer05-pak3
              docker load < result

              echo "Building Layer 06: CuPy..."
              nix build .#layer06-cupy
              docker load < result

              echo "Building Layer 07: pak5 Extended..."
              nix build .#layer07-pak5
              docker load < result

              echo "Building Layer 08: pak7 Face/Git..."
              nix build .#layer08-pak7
              docker load < result

              echo "Building Layer 09: SAM (placeholder)..."
              nix build .#layer09-sam
              docker load < result

              echo "Building Layer 10: Performance libs..."
              nix build .#layer10-performance
              docker load < result

              echo "Building Layer 11: Application scripts..."
              nix build .#layer11-app
              docker load < result

              echo "Building Layer 12: ComfyUI Bundle (Final)..."
              nix build .#layer12-comfyui
              ./result | docker load

              echo ""
              echo "Done! Image: comfyui-boot:cu130-megapak-py314-nix"
              echo ""
              echo "Verify packages:"
              docker run --rm comfyui-boot:cu130-megapak-py314-nix python -c "import torch; print(f'PyTorch {torch.__version__} CUDA {torch.version.cuda}')"
            '');
          };

          # Build final image directly
          build-final = {
            type = "app";
            program = toString (pkgs.writeScript "build-final" ''
              #!${pkgs.bash}/bin/bash
              set -e
              echo "Building final ComfyUI image..."
              nix build .#comfyui
              ./result | docker load
              echo "Done! Image: comfyui-boot:cu130-megapak-py314-nix"
            '');
          };

          # Helper to verify Python environment
          check-packages = {
            type = "app";
            program = toString (pkgs.writeScript "check-packages" ''
              #!${pkgs.bash}/bin/bash
              echo "Python environment packages:"
              ${pythonWithAllPackages}/bin/python -c "import sys; print('\\n'.join(sorted(sys.path)))"
              echo ""
              echo "Installed packages:"
              ${pythonWithAllPackages}/bin/python -m pip list
            '');
          };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonWithAllPackages
            pkgs.nix-prefetch-git
            pkgs.nix-prefetch-scripts
          ];

          shellHook = ''
            echo "ComfyUI Nix Development Environment (Layered Build)"
            echo "Python: ${pythonWithAllPackages}/bin/python3"
            echo ""
            echo "Available commands:"
            echo "  nix run .#build-all-layers  - Build all Docker layers incrementally"
            echo "  nix run .#build-final        - Build final image directly"
            echo "  nix run .#check-packages     - Verify Python environment"
            echo "  nix build .#layer01-base-cuda   - Build specific layer"
            echo "  nix build .#layer12-comfyui     - Build final layer"
            echo ""
            echo "Individual layers:"
            echo "  layer01: Base + CUDA"
            echo "  layer02: Python + Tools"
            echo "  layer03: GCC 15"
            echo "  layer04: PyTorch"
            echo "  layer05: pak3 (Core ML)"
            echo "  layer06: CuPy"
            echo "  layer07: pak5 (Extended)"
            echo "  layer08: pak7 (Face/Git)"
            echo "  layer09: SAM (TODO)"
            echo "  layer10: Performance libs"
            echo "  layer11: App scripts"
            echo "  layer12: ComfyUI Bundle"
            echo ""
          '';
        };
      }
    );
}
