{
  description = "ComfyUI Docker - Pure Nix build (no pip, no fakeRootCommands)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
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
        cudaPackages = pkgs.cudaPackages_13_0 or pkgs.cudaPackages_12;

        # Import custom Python packages
        customPythonPackages = pkgs.callPackage ./python-packages.nix {
          inherit python cudaPackages;
          pythonPackages = python.pkgs;
          buildPythonPackage = python.pkgs.buildPythonPackage;
          fetchFromGitHub = pkgs.fetchFromGitHub;
          fetchurl = pkgs.fetchurl;
        };

        #########################################################################
        # PYTHON ENVIRONMENT - All packages from Nix!
        #########################################################################

        pythonWithAllPackages = python.withPackages (ps: with ps; [
          # Build tools
          pip setuptools wheel packaging build

          #####################################################################
          # PYTORCH (from custom packages)
          #####################################################################
          customPythonPackages.torch
          # customPythonPackages.torchvision  # TODO: Access Denied - will retry
          customPythonPackages.torchaudio

          #####################################################################
          # PERFORMANCE LIBRARIES (from custom packages)
          #####################################################################
          customPythonPackages.flash-attn
          customPythonPackages.sageattention
          customPythonPackages.nunchaku
          customPythonPackages.cupy-cuda13x

          #####################################################################
          # GIT PACKAGES (from custom packages - built from source)
          #####################################################################
          customPythonPackages.clip
          customPythonPackages.cozy-comfyui
          customPythonPackages.cozy-comfy
          customPythonPackages.cstr
          customPythonPackages.ffmpy
          customPythonPackages.img2texture

          #####################################################################
          # PACKAGES FROM NIXPKGS (pak3.txt - essentials)
          #####################################################################
          # Core ML frameworks
          customPythonPackages.accelerate
          customPythonPackages.diffusers
          huggingface-hub
          transformers

          # Scientific computing
          numpy
          scipy
          pillow
          imageio
          scikit-learn
          scikit-image
          matplotlib
          pandas

          # Computer vision
          opencv4
          customPythonPackages.opencv-contrib-python
          customPythonPackages.opencv-contrib-python-headless
          customPythonPackages.kornia

          # ML utilities
          customPythonPackages.timm
          customPythonPackages.torchmetrics
          customPythonPackages.compel
          customPythonPackages.lark
          customPythonPackages.spandrel

          # Data formats
          pyyaml
          omegaconf
          # onnx  # TODO: check if available
          # onnxruntime  # Note: need GPU version

          # System utilities
          joblib
          psutil
          tqdm
          regex
          customPythonPackages.nvidia-ml-py

          #####################################################################
          # PACKAGES FROM NIXPKGS (pak5.txt)
          #####################################################################
          # HTTP/networking
          aiohttp
          requests
          urllib3

          # Data processing
          # albumentations  # TODO: check if available
          # av  # TODO: check if available
          einops
          numba
          numexpr

          # ML/AI tools
          # peft  # TODO: check if available
          safetensors
          sentencepiece
          tokenizers

          # Utilities
          customPythonPackages.addict
          cachetools
          chardet
          filelock
          customPythonPackages.loguru
          protobuf
          pydantic
          # pydub  # TODO: check if available
          rich
          toml
          typing-extensions

          # Version control
          gitpython

          # Database
          sqlalchemy

          #####################################################################
          # PACKAGES FROM PAK7 (face analysis and utilities)
          #####################################################################
          # dlib  # TODO: check if available in nixpkgs
          customPythonPackages.facexlib
          customPythonPackages.insightface

          #####################################################################
          # Additional packages from python-packages.nix
          #####################################################################
          customPythonPackages.ftfy
        ]);

        #########################################################################
        # DOCKER LAYERS - No fakeRootCommands needed!
        #########################################################################

        # Layer 0: Base system + CUDA
        layer0-base = pkgs.dockerTools.buildImage {
          name = "comfyui-layer0-base";
          tag = "latest";

          contents = pkgs.buildEnv {
            name = "base-env";
            ignoreCollisions = true;
            paths = with pkgs; [
              # System utilities
              bash coreutils findutils gnugrep gnused gnutar gzip which

              # CUDA (merged to avoid collisions)
              (pkgs.symlinkJoin {
                name = "cuda-merged";
                paths = [
                  cudaPackages.cudatoolkit
                  cudaPackages.cudnn
                ];
              })

              # Build tools
              gcc cmake ninja git

              # Media libraries
              ffmpeg x264 x265
            ];
          };

          config.Env = [
            "PATH=/usr/bin:/bin:${cudaPackages.cudatoolkit}/bin"
            "CUDA_HOME=${cudaPackages.cudatoolkit}"
            "LD_LIBRARY_PATH=${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudnn}/lib"
          ];
        };

        # Layer 1: Python with ALL packages (from Nix)
        layer1-python = pkgs.dockerTools.buildImage {
          name = "comfyui-layer1-python";
          tag = "latest";
          fromImage = layer0-base;

          contents = pkgs.buildEnv {
            name = "python-env";
            paths = [
              pythonWithAllPackages
              pkgs.aria2
              pkgs.vim
              pkgs.fish
            ];
          };

          config.Env = [
            "PYTHON=${pythonWithAllPackages}/bin/python3"
            "PYTHONUNBUFFERED=1"
            "PATH=/usr/bin:/bin:${pythonWithAllPackages}/bin"
          ];
        };

        # Layer 2: ComfyUI application files
        layer2-app = pkgs.dockerTools.buildImage {
          name = "comfyui-layer2-app";
          tag = "latest";
          fromImage = layer1-python;

          copyToRoot = pkgs.runCommand "app-scripts" {} ''
            mkdir -p $out/builder-scripts
            mkdir -p $out/runner-scripts
            mkdir -p $out/default-comfyui-bundle

            # Copy builder scripts
            ${pkgs.rsync}/bin/rsync -av ${./builder-scripts}/ $out/builder-scripts/
            chmod +x $out/builder-scripts/*.sh

            # Copy runner scripts
            ${pkgs.rsync}/bin/rsync -av ${./runner-scripts}/ $out/runner-scripts/
            chmod +x $out/runner-scripts/*.sh
          '';

          # No fakeRootCommands! Everything is already in the Python environment
          config.Env = [
            "PYTHONUNBUFFERED=1"
            "PATH=/usr/bin:/bin:${pythonWithAllPackages}/bin"
          ];
        };

        # Layer 3: ComfyUI setup (download and configure)
        layer3-comfyui = pkgs.dockerTools.buildImage {
          name = "comfyui-layer3-comfyui";
          tag = "latest";
          fromImage = layer2-app;

          # This still needs to run setup script, but no pip installs!
          # The setup script will:
          # 1. Clone ComfyUI
          # 2. Clone custom nodes
          # 3. Clone models (if needed)
          # 4. Configure settings
          # NO pip install needed - all packages from Nix!

          config.Env = [
            "PYTHONUNBUFFERED=1"
            "PATH=/usr/bin:/bin:${pythonWithAllPackages}/bin"
          ];
        };

        # Final image: Combine with proper runtime config
        finalImage = pkgs.dockerTools.streamLayeredImage {
          name = "comfyui-boot";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer3-comfyui;

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

      in {
        packages = {
          # Individual layers for incremental building
          inherit layer0-base layer1-python layer2-app layer3-comfyui;

          # Final image
          comfyui = finalImage;
          default = finalImage;

          # Expose Python environment for debugging
          inherit pythonWithAllPackages;
        };

        # Apps for building layers incrementally
        apps = {
          build-incremental = {
            type = "app";
            program = toString (pkgs.writeScript "build-incremental" ''
              #!${pkgs.bash}/bin/bash
              set -e

              echo "Building Layer 0: Base + CUDA..."
              nix build .#layer0-base
              docker load < result

              echo "Building Layer 1: Python + ALL packages (from Nix)..."
              nix build .#layer1-python
              docker load < result

              echo "Building Layer 2: Application scripts..."
              nix build .#layer2-app
              docker load < result

              echo "Building Layer 3: ComfyUI setup..."
              nix build .#layer3-comfyui
              docker load < result

              echo "Building final image..."
              nix build .#comfyui
              ./result | docker load

              echo "Done! Image: comfyui-boot:cu130-megapak-py314-nix"
              echo ""
              echo "Verify packages:"
              docker run --rm comfyui-boot:cu130-megapak-py314-nix python -c "import torch; print(f'PyTorch {torch.__version__} CUDA {torch.version.cuda}')"
            '');
          };

          # Helper to verify Python environment
          check-packages = {
            type = "app";
            program = toString (pkgs.writeScript "check-packages" ''
              #!${pkgs.bash}/bin/bash
              echo "Python environment packages:"
              ${pythonWithAllPackages}/bin/python -c "import sys; print('\n'.join(sorted(sys.path)))"
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
            echo "ComfyUI Nix Development Environment"
            echo "Python: ${pythonWithAllPackages}/bin/python3"
            echo ""
            echo "Available commands:"
            echo "  nix run .#build-incremental  - Build Docker image incrementally"
            echo "  nix run .#check-packages     - Verify Python environment"
            echo "  nix-prefetch-url <url>       - Get hash for wheel URLs"
            echo ""
          '';
        };
      }
    );
}

# Pure Nix Approach - Key Benefits:
#
# ✅ NO pip installs during build
# ✅ NO fakeRootCommands needed
# ✅ Fully reproducible (all packages from Nix)
# ✅ Better caching (Nix knows exact dependencies)
# ✅ Garbage collection (old versions cleaned automatically)
# ✅ Can use nix-shell for local development
# ✅ Dependency tracking (Nix manages the DAG)
#
# TODO:
# 1. Fill in sha256 hashes in python-packages.nix
# 2. Expand python-packages.nix with remaining packages from pak files
# 3. Verify package availability in nixpkgs (check comments above)
# 4. Test build: nix run .#build-incremental
