{
  description = "ComfyUI Docker - Proper layered Nix build";

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

        #########################################################################
        # DOWNLOAD LAYER - Fetch all wheels and sources
        #########################################################################

        # PyTorch wheels from official index
        pytorchWheels = {
          torch = pkgs.fetchurl {
            url = "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl";
            hash = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: nix-prefetch-url
          };
          torchvision = pkgs.fetchurl {
            url = "https://download.pytorch.org/whl/cu130/torchvision-0.20.0%2Bcu130-cp314-cp314-linux_x86_64.whl";
            hash = "sha256-0000000000000000000000000000000000000000000000000000";
          };
          torchaudio = pkgs.fetchurl {
            url = "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl";
            hash = "sha256-0000000000000000000000000000000000000000000000000000";
          };
        };

        # Performance wheels from custom builder
        perfWheels = {
          flashAttn = pkgs.fetchurl {
            url = "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl";
            hash = "sha256-0000000000000000000000000000000000000000000000000000";
          };
          sageattention = pkgs.fetchurl {
            url = "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl";
            hash = "sha256-0000000000000000000000000000000000000000000000000000";
          };
          nunchaku = pkgs.fetchurl {
            url = "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl";
            hash = "sha256-0000000000000000000000000000000000000000000000000000";
          };
        };

        #########################################################################
        # PYTHON PACKAGES - Use Nix where available, wheels otherwise
        #########################################################################

        # Python environment with packages from nixpkgs
        pythonWithPackages = python.withPackages (ps: with ps; [
          # Core packages from nixpkgs
          pip setuptools wheel packaging

          # Scientific computing (available in nixpkgs)
          numpy
          scipy
          pillow
          imageio

          # ML/AI packages (available in nixpkgs)
          scikit-learn
          scikit-image
          opencv4

          # Data formats
          pyyaml

          # HTTP/networking
          requests
          urllib3

          # Utilities available in nixpkgs
          tqdm
          psutil

          # Add more from pak files that exist in nixpkgs
        ]);

        #########################################################################
        # BUILD DERIVATIONS - Build from source where needed
        #########################################################################

        # SAM-2 from source
        sam2 = pkgs.stdenv.mkDerivation {
          name = "sam2";
          src = pkgs.fetchFromGitHub {
            owner = "facebookresearch";
            repo = "sam2";
            rev = "main";  # TODO: pin to specific commit
            sha256 = "sha256-0000000000000000000000000000000000000000000000000000";
          };

          buildInputs = [ pythonWithPackages ];

          buildPhase = ''
            export SAM2_BUILD_CUDA=1
            ${pythonWithPackages}/bin/python setup.py build
          '';

          installPhase = ''
            ${pythonWithPackages}/bin/pip install --no-deps --no-build-isolation -e . --prefix=$out
          '';
        };

        # SAM-3 from source
        sam3 = pkgs.stdenv.mkDerivation {
          name = "sam3";
          src = pkgs.fetchFromGitHub {
            owner = "facebookresearch";
            repo = "sam3";
            rev = "main";
            sha256 = "sha256-0000000000000000000000000000000000000000000000000000";
          };

          buildInputs = [ pythonWithPackages ];

          buildPhase = ''
            ${pythonWithPackages}/bin/python setup.py build
          '';

          installPhase = ''
            ${pythonWithPackages}/bin/pip install --no-deps --no-build-isolation -e . --prefix=$out
          '';
        };

        #########################################################################
        # DOCKER LAYERS - Build incrementally
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

              # CUDA (use symlinkJoin to avoid collisions)
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

        # Layer 1: Python + system packages from nixpkgs
        layer1-python = pkgs.dockerTools.buildImage {
          name = "comfyui-layer1-python";
          tag = "latest";
          fromImage = layer0-base;

          contents = pkgs.buildEnv {
            name = "python-env";
            paths = [
              pythonWithPackages
              pkgs.aria2
              pkgs.vim
              pkgs.fish
            ];
          };

          config.Env = [
            "PYTHON=${python}/bin/python3"
            "PYTHONUNBUFFERED=1"
            "PATH=/usr/bin:/bin:${python}/bin"
          ];
        };

        # Layer 2: Downloaded wheels (no build, just copy)
        layer2-wheels = pkgs.dockerTools.buildImage {
          name = "comfyui-layer2-wheels";
          tag = "latest";
          fromImage = layer1-python;

          copyToRoot = pkgs.runCommand "wheels-dir" {} ''
            mkdir -p $out/opt/wheels/pytorch
            mkdir -p $out/opt/wheels/perf

            # Copy PyTorch wheels
            cp ${pytorchWheels.torch} $out/opt/wheels/pytorch/torch.whl
            cp ${pytorchWheels.torchvision} $out/opt/wheels/pytorch/torchvision.whl
            cp ${pytorchWheels.torchaudio} $out/opt/wheels/pytorch/torchaudio.whl

            # Copy performance wheels
            cp ${perfWheels.flashAttn} $out/opt/wheels/perf/flash_attn.whl
            cp ${perfWheels.sageattention} $out/opt/wheels/perf/sageattention.whl
            cp ${perfWheels.nunchaku} $out/opt/wheels/perf/nunchaku.whl
          '';
        };

        # Layer 3: PyTorch installed (from local wheels)
        layer3-pytorch = pkgs.dockerTools.buildImage {
          name = "comfyui-layer3-pytorch";
          tag = "latest";
          fromImage = layer2-wheels;

          # Use fakeRootCommands instead of runAsRoot (no VM!)
          fakeRootCommands = ''
            # Install PyTorch from pre-downloaded wheels
            ${pythonWithPackages}/bin/pip install --no-cache-dir \
              --no-index \
              --find-links /opt/wheels/pytorch \
              torch torchvision torchaudio

            # Verify installation
            ${pythonWithPackages}/bin/python -c "import torch; print(f'PyTorch {torch.__version__} with CUDA {torch.version.cuda}')"
          '';
        };

        # Layer 4: Additional dependencies from nixpkgs + remaining pip packages
        layer4-deps = pkgs.dockerTools.buildImage {
          name = "comfyui-layer4-deps";
          tag = "latest";
          fromImage = layer3-pytorch;

          copyToRoot = pkgs.buildEnv {
            name = "deps-env";
            paths = [
              sam2
              sam3
            ];
          };

          # Copy scripts
          extraCommands = ''
            mkdir -p builder-scripts
            cp -r ${./builder-scripts}/* builder-scripts/
            chmod +x builder-scripts/*.sh
          '';

          fakeRootCommands = ''
            # Install remaining packages from pak files that aren't in nixpkgs
            # Filter out packages we already have from Nix
            ${pythonWithPackages}/bin/pip install --no-cache-dir -r /builder-scripts/pak3.txt || true
            ${pythonWithPackages}/bin/pip install --no-cache-dir -r /builder-scripts/pak5.txt || true
            ${pythonWithPackages}/bin/pip install --no-cache-dir -r /builder-scripts/pak7.txt || true
          '';
        };

        # Layer 5: Performance wheels installed
        layer5-perf = pkgs.dockerTools.buildImage {
          name = "comfyui-layer5-perf";
          tag = "latest";
          fromImage = layer4-deps;

          fakeRootCommands = ''
            # Install performance wheels from pre-downloaded files
            ${pythonWithPackages}/bin/pip install --no-cache-dir \
              --no-index \
              --find-links /opt/wheels/perf \
              flash-attn sageattention nunchaku

            # Verify
            ${pythonWithPackages}/bin/pip list | grep -E "(flash-attn|sageattention|nunchaku)"
          '';
        };

        # Layer 6: ComfyUI application
        layer6-app = pkgs.dockerTools.buildImage {
          name = "comfyui-layer6-app";
          tag = "latest";
          fromImage = layer5-perf;

          extraCommands = ''
            mkdir -p runner-scripts default-comfyui-bundle
            cp -r ${./runner-scripts}/* runner-scripts/
            chmod +x runner-scripts/*.sh
          '';

          fakeRootCommands = ''
            # Setup ComfyUI
            cd /default-comfyui-bundle
            bash /builder-scripts/preload-cache.sh

            # Install ComfyUI requirements
            ${pythonWithPackages}/bin/pip install --no-cache-dir \
              -r /default-comfyui-bundle/ComfyUI/requirements.txt \
              -r /default-comfyui-bundle/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt

            # Final package list
            ${pythonWithPackages}/bin/pip list > /package-list.txt
          '';
        };

        # Final image: Combine all layers with proper config
        finalImage = pkgs.dockerTools.buildImage {
          name = "comfyui-boot";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer6-app;

          config = {
            Cmd = [ "${pkgs.bash}/bin/bash" "/runner-scripts/entrypoint.sh" ];
            WorkingDir = "/root";
            ExposedPorts = {
              "8188/tcp" = {};
            };
            Env = [
              "CLI_ARGS="
              "PYTHONUNBUFFERED=1"
              "PATH=/usr/bin:/bin:${python}/bin"
            ];
            Volumes = {
              "/root" = {};
            };
          };
        };

      in {
        packages = {
          # Individual layers for incremental building
          inherit layer0-base layer1-python layer2-wheels
                  layer3-pytorch layer4-deps layer5-perf layer6-app;

          # Final image
          comfyui = finalImage;
          default = finalImage;
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

              echo "Building Layer 1: Python + nixpkgs packages..."
              nix build .#layer1-python
              docker load < result

              echo "Building Layer 2: Download wheels..."
              nix build .#layer2-wheels
              docker load < result

              echo "Building Layer 3: Install PyTorch..."
              nix build .#layer3-pytorch
              docker load < result

              echo "Building Layer 4: Dependencies..."
              nix build .#layer4-deps
              docker load < result

              echo "Building Layer 5: Performance wheels..."
              nix build .#layer5-perf
              docker load < result

              echo "Building Layer 6: ComfyUI app..."
              nix build .#layer6-app
              docker load < result

              echo "Building final image..."
              nix build .#comfyui
              ./result | docker load

              echo "Done! Image: comfyui-boot:cu130-megapak-py314-nix"
            '');
          };
        };
      }
    );
}

# How to use:
# 1. Fill in sha256 hashes using: nix-prefetch-url <url>
# 2. Build incrementally: nix run .#build-incremental
# 3. Or build specific layer: nix build .#layer3-pytorch
# 4. Each layer is cached independently!
