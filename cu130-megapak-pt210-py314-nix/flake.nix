{
  description = "ComfyUI Docker Image - CUDA 13.0 with Python 3.14 (free-threaded)";

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

        # Python 3.14 with free-threading (no GIL)
        python = pkgs.python314;

        # CUDA packages
        cudaPackages = pkgs.cudaPackages_13_0 or pkgs.cudaPackages_12;

        #########################################################################
        # Layer 1: Base system with CUDA
        #########################################################################
        baseLayer = pkgs.dockerTools.buildImage {
          name = "comfyui-base";
          tag = "cuda130";

          copyToRoot = pkgs.buildEnv {
            name = "base-root";
            ignoreCollisions = true;  # Allow LICENSE file conflicts between CUDA packages
            paths = with pkgs; [
              # Core system utilities
              bash
              coreutils
              findutils
              gnugrep
              gnused
              gnutar
              gzip
              which

              # CUDA toolkit
              cudaPackages.cudatoolkit
              cudaPackages.cudnn

              # Build tools
              gcc
              cmake
              ninja
              git

              # Media tools
              ffmpeg
              x264
              x265
            ];
          };

          config = {
            Env = [
              "PATH=/usr/bin:/bin:${cudaPackages.cudatoolkit}/bin"
              "CUDA_HOME=${cudaPackages.cudatoolkit}"
              "LD_LIBRARY_PATH=${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudnn}/lib"
            ];
          };
        };

        #########################################################################
        # Layer 2: Python 3.14 environment
        #########################################################################
        pythonLayer = pkgs.dockerTools.buildImage {
          name = "comfyui-python";
          tag = "py314";
          fromImage = baseLayer;

          copyToRoot = pkgs.buildEnv {
            name = "python-root";
            paths = [
              python
              python.pkgs.pip
              python.pkgs.setuptools
              python.pkgs.wheel
            ];
          };

          config = {
            Env = [
              "PYTHON=${python}/bin/python3"
              "PYTHONUNBUFFERED=1"
            ];
          };
        };

        #########################################################################
        # Layer 3: PyTorch and core ML libraries
        #########################################################################
        pytorchLayer = let
          # Create a Python environment with PyTorch
          pythonEnv = python.withPackages (ps: with ps; [
            # Core packages
            pip
            setuptools
            wheel
            packaging

            # Will install PyTorch via pip in runtime for CUDA 13.0 compatibility
          ]);
        in pkgs.dockerTools.buildImage {
          name = "comfyui-pytorch";
          tag = "cu130";
          fromImage = pythonLayer;

          copyToRoot = pkgs.buildEnv {
            name = "pytorch-root";
            paths = [ pythonEnv ];
          };

          runAsRoot = ''
            #!${pkgs.runtimeShell}
            # Install PyTorch with CUDA 13.0 support
            ${pythonEnv}/bin/pip install --no-cache-dir torch torchvision torchaudio \
              --index-url https://download.pytorch.org/whl/cu130 || \
            ${pythonEnv}/bin/pip install --no-cache-dir --pre torch torchvision torchaudio \
              --index-url https://download.pytorch.org/whl/nightly/cu130
          '';
        };

        #########################################################################
        # Layer 4: ComfyUI Python dependencies
        #########################################################################
        dependenciesLayer = let
          builderScripts = ./builder-scripts;
        in pkgs.dockerTools.buildImage {
          name = "comfyui-deps";
          tag = "latest";
          fromImage = pytorchLayer;

          contents = pkgs.buildEnv {
            name = "deps-root";
            paths = with pkgs; [
              # Additional tools needed for ComfyUI
              aria2
              vim
              fish
            ];
          };

          runAsRoot = ''
            #!${pkgs.runtimeShell}
            # Copy builder scripts
            mkdir -p /builder-scripts
            cp -r ${builderScripts}/* /builder-scripts/
            chmod +x /builder-scripts/*.sh

            # Install Python dependencies from pak files
            ${python}/bin/pip install --no-cache-dir -r /builder-scripts/pak3.txt
            ${python}/bin/pip install --no-cache-dir -r /builder-scripts/pak5.txt
            ${python}/bin/pip install --no-cache-dir -r /builder-scripts/pak7.txt

            # Install SAM-2 (prevent CUDA package conflicts)
            cd /builder-scripts
            ${pkgs.git}/bin/git clone https://github.com/facebookresearch/sam2.git
            cd sam2
            SAM2_BUILD_CUDA=1 ${python}/bin/pip install --no-cache-dir \
              -e . --no-deps --no-build-isolation
            cd /

            # Install SAM-3 (prevent NumPy1 conflicts)
            cd /builder-scripts
            ${pkgs.git}/bin/git clone https://github.com/facebookresearch/sam3.git
            cd sam3
            ${python}/bin/pip install --no-cache-dir \
              -e . --no-deps --no-build-isolation
            cd /
          '';
        };

        #########################################################################
        # Layer 5: Performance optimization wheels
        #########################################################################
        performanceLayer = pkgs.dockerTools.buildImage {
          name = "comfyui-performance";
          tag = "latest";
          fromImage = dependenciesLayer;

          runAsRoot = ''
            #!${pkgs.runtimeShell}
            # Install custom-built performance wheels
            ${python}/bin/pip install --no-cache-dir \
              https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl

            ${python}/bin/pip install --no-cache-dir \
              https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl

            ${python}/bin/pip install --no-cache-dir \
              https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl
          '';
        };

        #########################################################################
        # Layer 6: ComfyUI application bundle
        #########################################################################
        comfyuiLayer = pkgs.dockerTools.buildImage {
          name = "comfyui-app";
          tag = "latest";
          fromImage = performanceLayer;

          runAsRoot = ''
            #!${pkgs.runtimeShell}
            # Clone and setup ComfyUI using preload script
            mkdir -p /default-comfyui-bundle
            cd /default-comfyui-bundle

            # Run the preload cache script to install ComfyUI + custom nodes
            ${pkgs.bash}/bin/bash /builder-scripts/preload-cache.sh

            # Install ComfyUI and Manager requirements
            ${python}/bin/pip install --no-cache-dir \
              -r /default-comfyui-bundle/ComfyUI/requirements.txt \
              -r /default-comfyui-bundle/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt

            # List installed packages for verification
            ${python}/bin/pip list
          '';
        };

        #########################################################################
        # Final Image: Complete ComfyUI with runtime config
        #########################################################################
        finalImage = let
          runnerScripts = ./runner-scripts;
        in pkgs.dockerTools.streamLayeredImage {
          name = "comfyui-boot";
          tag = "cu130-megapak-py314-nix";
          fromImage = comfyuiLayer;

          contents = pkgs.buildEnv {
            name = "runtime-root";
            paths = [ pkgs.bash ];
          };

          extraCommands = ''
            # Copy runner scripts
            mkdir -p runner-scripts
            cp -r ${runnerScripts}/* runner-scripts/
            chmod +x runner-scripts/*.sh
          '';

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

          # Maximum number of layers (Docker supports up to 125)
          maxLayers = 100;
        };

      in {
        packages = {
          # Individual layers for development/debugging
          inherit baseLayer pythonLayer pytorchLayer
                  dependenciesLayer performanceLayer comfyuiLayer;

          # Final image
          default = finalImage;
          comfyui = finalImage;
        };

        # Development shell for testing
        devShells.default = pkgs.mkShell {
          buildInputs = [
            python
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            pkgs.git
          ];

          shellHook = ''
            export CUDA_HOME=${cudaPackages.cudatoolkit}
            export LD_LIBRARY_PATH=${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudnn}/lib
            echo "ComfyUI Development Environment"
            echo "Python: $(python3 --version)"
            echo "CUDA: ${cudaPackages.cudatoolkit.version}"
          '';
        };

        # Apps for easy building
        apps = {
          # Build individual layers
          build-base = {
            type = "app";
            program = toString (pkgs.writeScript "build-base" ''
              #!${pkgs.bash}/bin/bash
              nix build .#baseLayer
              docker load < result
            '');
          };

          # Build and load final image
          build = {
            type = "app";
            program = toString (pkgs.writeScript "build-final" ''
              #!${pkgs.bash}/bin/bash
              nix build .#comfyui
              ./result | docker load
            '');
          };

          # Run the image
          run = {
            type = "app";
            program = toString (pkgs.writeScript "run-comfyui" ''
              #!${pkgs.bash}/bin/bash
              docker run --rm -it \
                --gpus all \
                -p 8188:8188 \
                -v "$(pwd)/output:/root/output" \
                comfyui-boot:cu130-megapak-py314-nix
            '');
          };
        };
      }
    );
}
