{
  description = "ComfyUI Docker - Pure Nix build with nix2container (zero duplication)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, nix2container }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        nix2containerPkgs = nix2container.packages.${system};

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

        # Helper function to chain layers and avoid duplication
        # Based on: https://blog.eigenvalue.net/2023-nix2container-everything-once/
        foldImageLayers = let
          mergeToLayer = priorLayers: component:
            assert builtins.isList priorLayers;
            assert builtins.isAttrs component;
            let
              layer = nix2containerPkgs.nix2container.buildLayer (component // {
                layers = priorLayers;
              });
            in
            priorLayers ++ [ layer ];
        in
        layers: builtins.foldl' mergeToLayer [] layers;

        # Layer definitions (explicit, logical grouping)
        layerDefs = [
          # Layer 01: Base system utilities
          {
            deps = with pkgs; [
              bash
              coreutils
              findutils
              gnugrep
              gnused
              gnutar
              gzip
              bzip2
              xz
              which
            ];
          }

          # Layer 02: CUDA Toolkit + cuDNN
          {
            deps = [
              cudaPackages.cudatoolkit
              cudaPackages.cudnn
            ];
          }

          # Layer 03: Build tools and media libraries
          {
            deps = with pkgs; [
              gcc
              cmake
              ninja
              git
              ffmpeg
              x264
              x265
            ];
          }

          # Layer 04: Python 3.14 base
          {
            deps = [ python ];
          }

          # Layer 05: GCC 15
          {
            deps = with pkgs; [
              gcc15
              binutils
            ];
          }

          # Layer 06: PyTorch ecosystem
          {
            deps = with python.pkgs; [
              customPackages.torch
              torchvision
              customPackages.torchaudio
            ];
          }

          # Layer 07: pak3 - Core ML packages
          {
            deps = with python.pkgs; [
              # Build tools
              pip setuptools wheel packaging build

              # Core ML frameworks (custom packages)
              pak3Packages.accelerate
              pak3Packages.diffusers

              # Core ML frameworks (from nixpkgs)
              huggingface-hub
              transformers

              # Scientific computing
              numpy scipy pillow imageio scikit-learn scikit-image matplotlib pandas seaborn

              # Computer vision
              opencv4
              pak3Packages.opencv-contrib-python
              pak3Packages.opencv-contrib-python-headless
              pak3Packages.kornia

              # ML utilities (custom packages)
              pak3Packages.timm
              pak3Packages.torchmetrics
              pak3Packages.compel
              pak3Packages.lark

              # Data formats
              pyyaml omegaconf onnx onnxruntime

              # System utilities
              joblib psutil tqdm regex einops
              pak3Packages.nvidia-ml-py
              pak3Packages.ftfy
            ];
          }

          # Layer 08: CuPy
          {
            deps = [ customPackages.cupy-cuda13x ];
          }

          # Layer 09: pak5 - Extended libraries
          {
            deps = with python.pkgs; [
              # Custom packages
              pak5Packages.addict
              pak5Packages.loguru
              pak5Packages.spandrel

              # HTTP/networking
              aiohttp requests urllib3

              # Data processing
              albumentations av numba numexpr

              # ML/AI tools
              peft safetensors sentencepiece tokenizers

              # Utilities
              protobuf pydantic rich sqlalchemy

              # Geometry
              shapely trimesh

              # Additional
              webcolors qrcode yarl tomli pycocotools
            ];
          }

          # Layer 10: pak7 - Face analysis + Git packages
          {
            deps = [
              # Face analysis
              python.pkgs.dlib
              pak7Packages.facexlib
              pak7Packages.insightface

              # Git packages
              pak7Packages.clip
              pak7Packages.cozy-comfyui
              pak7Packages.cozy-comfy
              pak7Packages.cstr
              pak7Packages.ffmpy
              pak7Packages.img2texture
            ];
          }

          # Layer 11: Performance libraries
          {
            deps = [
              customPackages.flash-attn
              customPackages.sageattention
              customPackages.nunchaku
            ];
          }

          # Layer 12: Application scripts and utilities
          {
            deps = with pkgs; [
              aria2
              vim
              fish
            ];
          }
        ];

        # Build all layers with automatic deduplication
        imageLayers = foldImageLayers layerDefs;

        # Application scripts to copy to root
        builderScripts = pkgs.runCommand "builder-scripts" {} ''
          mkdir -p $out/builder-scripts
          echo "#!/bin/bash" > $out/builder-scripts/placeholder.sh
          echo "echo 'Builder scripts placeholder'" >> $out/builder-scripts/placeholder.sh
          chmod +x $out/builder-scripts/placeholder.sh
        '';

        runnerScripts = pkgs.runCommand "runner-scripts" {} ''
          mkdir -p $out/runner-scripts
          cat > $out/runner-scripts/entrypoint.sh << 'EOF'
          #!/bin/bash
          set -e

          echo "ComfyUI Container (Nix2Container)"
          echo "Python: $(python --version)"
          echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
          echo "CUDA: $(python -c 'import torch; print(torch.version.cuda)')"

          exec "$@"
          EOF
          chmod +x $out/runner-scripts/entrypoint.sh
        '';

        # Final image with all layers
        comfyuiImage = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-boot";
          tag = "cu130-megapak-py314-nix-nix2container";

          # Use all pre-built layers
          layers = imageLayers;

          # Copy application scripts to root
          copyToRoot = [
            builderScripts
            runnerScripts
          ];

          # Image configuration
          config = {
            Cmd = [ "${pkgs.bash}/bin/bash" "/runner-scripts/entrypoint.sh" ];
            WorkingDir = "/root";
            ExposedPorts = {
              "8188/tcp" = {};
            };
            Env = [
              "PATH=/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
              "PYTHONPATH=${python.withPackages (ps: packageList.all)}/lib/python3.14/site-packages"
              "CUDA_HOME=${cudaPackages.cudatoolkit}"
              "LD_LIBRARY_PATH=${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudnn}/lib"
              "CC=${pkgs.gcc15}/bin/gcc"
              "CXX=${pkgs.gcc15}/bin/g++"
              "CPP=${pkgs.gcc15}/bin/cpp"
            ];
          };
        };

        # Individual layer packages for caching
        # Build cumulative layers independently so workflows can cache them
        # Layer 0: Base system + CUDA (layers 0-1 from layerDefs)
        layer0-base = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-layer0-base";
          tag = "cuda130";
          layers = foldImageLayers [
            (builtins.elemAt layerDefs 0)  # Base system utilities
            (builtins.elemAt layerDefs 1)  # CUDA + cuDNN
          ];
          config = {
            Cmd = [ "${pkgs.bash}/bin/bash" ];
          };
        };

        # Layer 1: Base + CUDA + Build tools + Python (layers 0-3)
        layer1-python = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-layer1-python";
          tag = "py314";
          layers = foldImageLayers [
            (builtins.elemAt layerDefs 0)  # Base
            (builtins.elemAt layerDefs 1)  # CUDA
            (builtins.elemAt layerDefs 2)  # Build tools
            (builtins.elemAt layerDefs 3)  # Python 3.14
          ];
          config = {
            Cmd = [ "${python}/bin/python3" ];
          };
        };

        # Layer 2: + GCC 15 (layers 0-4)
        layer2-wheels = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-layer2-wheels";
          tag = "latest";
          layers = foldImageLayers [
            (builtins.elemAt layerDefs 0)
            (builtins.elemAt layerDefs 1)
            (builtins.elemAt layerDefs 2)
            (builtins.elemAt layerDefs 3)
            (builtins.elemAt layerDefs 4)  # GCC 15
          ];
          config = {
            Cmd = [ "${python}/bin/python3" ];
          };
        };

        # Layer 3: + PyTorch (layers 0-5)
        layer3-pytorch = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-layer3-pytorch";
          tag = "cu130";
          layers = foldImageLayers [
            (builtins.elemAt layerDefs 0)
            (builtins.elemAt layerDefs 1)
            (builtins.elemAt layerDefs 2)
            (builtins.elemAt layerDefs 3)
            (builtins.elemAt layerDefs 4)
            (builtins.elemAt layerDefs 5)  # PyTorch
          ];
          config = {
            Cmd = [ "${python}/bin/python3" ];
            Env = [
              "PYTHONPATH=${python.withPackages (ps: [ customPackages.torch ps.torchvision customPackages.torchaudio ])}/lib/python3.14/site-packages"
            ];
          };
        };

        # Layer 4: + pak3 + CuPy + pak5 (layers 0-8)
        layer4-deps = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-layer4-deps";
          tag = "latest";
          layers = foldImageLayers [
            (builtins.elemAt layerDefs 0)
            (builtins.elemAt layerDefs 1)
            (builtins.elemAt layerDefs 2)
            (builtins.elemAt layerDefs 3)
            (builtins.elemAt layerDefs 4)
            (builtins.elemAt layerDefs 5)
            (builtins.elemAt layerDefs 6)  # pak3
            (builtins.elemAt layerDefs 7)  # CuPy
            (builtins.elemAt layerDefs 8)  # pak5
          ];
          config = {
            Cmd = [ "${python}/bin/python3" ];
          };
        };

        # Layer 5: + pak7 + Performance libs (layers 0-10)
        layer5-perf = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-layer5-perf";
          tag = "latest";
          layers = foldImageLayers [
            (builtins.elemAt layerDefs 0)
            (builtins.elemAt layerDefs 1)
            (builtins.elemAt layerDefs 2)
            (builtins.elemAt layerDefs 3)
            (builtins.elemAt layerDefs 4)
            (builtins.elemAt layerDefs 5)
            (builtins.elemAt layerDefs 6)
            (builtins.elemAt layerDefs 7)
            (builtins.elemAt layerDefs 8)
            (builtins.elemAt layerDefs 9)  # pak7
            (builtins.elemAt layerDefs 10) # Performance libs
          ];
          config = {
            Cmd = [ "${python}/bin/python3" ];
          };
        };

        # Layer 6: Full image with all layers + app scripts
        layer6-app = nix2containerPkgs.nix2container.buildImage {
          name = "comfyui-layer6-app";
          tag = "latest";
          layers = imageLayers; # all layers (0-11)
          copyToRoot = [
            builderScripts
            runnerScripts
          ];
          config = {
            Cmd = [ "${pkgs.bash}/bin/bash" "/runner-scripts/entrypoint.sh" ];
            Env = [
              "PYTHONPATH=${python.withPackages (ps: packageList.all)}/lib/python3.14/site-packages"
            ];
          };
        };

      in {
        packages = {
          # Main image
          comfyui = comfyuiImage;
          default = comfyuiImage;

          # Individual layers for caching
          inherit layer0-base layer1-python layer2-wheels layer3-pytorch layer4-deps layer5-perf layer6-app;

          # Expose Python environment for debugging
          pythonWithAllPackages = python.withPackages (ps: packageList.all);
        };

        # Apps for building and testing
        apps = {
          # Build and load image
          build = {
            type = "app";
            program = toString (pkgs.writeScript "build-nix2container" ''
              #!${pkgs.bash}/bin/bash
              set -e

              echo "Building ComfyUI image with nix2container..."
              nix build .#comfyui --show-trace

              echo ""
              echo "Loading image into Docker..."
              ./result | docker load

              echo ""
              echo "Done! Image: comfyui-boot:cu130-megapak-py314-nix-nix2container"
              echo ""
              echo "Verify packages:"
              docker run --rm comfyui-boot:cu130-megapak-py314-nix-nix2container \
                python -c "import torch; print(f'PyTorch {torch.__version__} CUDA {torch.version.cuda}')"
            '');
          };

          # Copy to registry (Skopeo-based, fast!)
          push-ghcr = {
            type = "app";
            program = toString (pkgs.writeScript "push-ghcr" ''
              #!${pkgs.bash}/bin/bash
              set -e

              REGISTRY="ghcr.io/$GITHUB_REPOSITORY_OWNER"
              IMAGE_NAME="comfyui-nix2container"
              TAG="cu130-megapak-py314"

              echo "Building and pushing to $REGISTRY/$IMAGE_NAME:$TAG"

              # nix2container supports direct push without docker daemon
              nix run .#comfyui.copyToRegistry -- \
                --dest-creds "$GITHUB_ACTOR:$GITHUB_TOKEN" \
                $REGISTRY/$IMAGE_NAME:$TAG

              echo "Pushed to $REGISTRY/$IMAGE_NAME:$TAG"
            '');
          };

          # Verify Python environment
          check-packages = {
            type = "app";
            program = toString (pkgs.writeScript "check-packages" ''
              #!${pkgs.bash}/bin/bash
              echo "Python environment packages:"
              ${python.withPackages (ps: packageList.all)}/bin/python -c "import sys; print('\\n'.join(sorted(sys.path)))"
              echo ""
              echo "Installed packages:"
              ${python.withPackages (ps: packageList.all)}/bin/python -m pip list
            '');
          };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [
            (python.withPackages (ps: packageList.all))
            pkgs.nix-prefetch-git
            pkgs.nix-prefetch-scripts
            pkgs.skopeo  # For registry operations
          ];

          shellHook = ''
            echo "ComfyUI Nix Development Environment (nix2container)"
            echo "Python: ${python}/bin/python3"
            echo ""
            echo "Available commands:"
            echo "  nix run .#build           - Build and load Docker image"
            echo "  nix run .#push-ghcr       - Push to GHCR (requires auth)"
            echo "  nix run .#check-packages  - Verify Python environment"
            echo ""
            echo "Layer architecture:"
            echo "  01: Base system utilities"
            echo "  02: CUDA Toolkit + cuDNN"
            echo "  03: Build tools (gcc, cmake, git, ffmpeg)"
            echo "  04: Python 3.14"
            echo "  05: GCC 15"
            echo "  06: PyTorch + torchvision + torchaudio"
            echo "  07: pak3 (Core ML essentials - ~42 packages)"
            echo "  08: CuPy CUDA 13.x"
            echo "  09: pak5 (Extended libraries - ~72 packages)"
            echo "  10: pak7 (Face analysis + Git packages)"
            echo "  11: Performance (flash-attn, sageattention, nunchaku)"
            echo "  12: Application scripts"
            echo ""
            echo "Benefits of nix2container:"
            echo "  ✓ Zero package duplication across layers"
            echo "  ✓ Automatic dependency deduplication"
            echo "  ✓ Faster builds (no tarball in Nix store)"
            echo "  ✓ Direct registry push (skip docker load)"
            echo "  ✓ Efficient layer caching"
            echo ""
          '';
        };
      }
    );
}
