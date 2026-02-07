{
  description = "ComfyUI Docker Image - CUDA 13.0 with Python 3.14 (simplified, no VM)";

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

        # Build setup script that will run on container startup
        setupScript = pkgs.writeShellScriptBin "setup-comfyui" ''
          #!/bin/bash
          set -e

          # Only run setup once
          if [ -f /var/lib/comfyui-setup-done ]; then
            exit 0
          fi

          echo "Installing PyTorch with CUDA 13.0..."
          ${python}/bin/pip install --no-cache-dir torch torchvision torchaudio \
            --index-url https://download.pytorch.org/whl/cu130 || \
          ${python}/bin/pip install --no-cache-dir --pre torch torchvision torchaudio \
            --index-url https://download.pytorch.org/whl/nightly/cu130

          echo "Installing Python dependencies..."
          ${python}/bin/pip install --no-cache-dir -r /builder-scripts/pak3.txt
          ${python}/bin/pip install --no-cache-dir -r /builder-scripts/pak5.txt
          ${python}/bin/pip install --no-cache-dir -r /builder-scripts/pak7.txt

          echo "Installing performance wheels..."
          ${python}/bin/pip install --no-cache-dir \
            https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl
          ${python}/bin/pip install --no-cache-dir \
            https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl
          ${python}/bin/pip install --no-cache-dir \
            https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl

          echo "Setting up ComfyUI..."
          cd /default-comfyui-bundle
          bash /builder-scripts/preload-cache.sh

          ${python}/bin/pip install --no-cache-dir \
            -r /default-comfyui-bundle/ComfyUI/requirements.txt \
            -r /default-comfyui-bundle/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt

          # Mark setup as done
          touch /var/lib/comfyui-setup-done
          echo "Setup complete!"
        '';

        # Entrypoint that runs setup then starts ComfyUI
        entrypointScript = pkgs.writeShellScriptBin "entrypoint" ''
          #!/bin/bash
          # Run setup on first start
          ${setupScript}/bin/setup-comfyui

          # Then run the actual entrypoint
          exec bash /runner-scripts/entrypoint.sh
        '';

        # Build environment with all system packages
        systemEnv = pkgs.buildEnv {
          name = "system-env";
          ignoreCollisions = true;
          paths = with pkgs; [
            # Core utilities
            bash coreutils findutils gnugrep gnused gnutar gzip which

            # CUDA
            cudaPackages.cudatoolkit
            cudaPackages.cudnn

            # Build tools
            gcc cmake ninja git

            # Media
            ffmpeg x264 x265

            # Python
            python
            python.pkgs.pip
            python.pkgs.setuptools
            python.pkgs.wheel

            # Additional tools
            aria2 vim fish

            # Scripts
            setupScript
            entrypointScript
          ];
        };

      in {
        packages = {
          # Single-layer approach - no VM needed!
          comfyui = pkgs.dockerTools.streamLayeredImage {
            name = "comfyui-boot";
            tag = "cu130-megapak-py314-nix";

            contents = [ systemEnv ];

            # Copy scripts directly (no runAsRoot needed)
            extraCommands = ''
              # Create necessary directories
              mkdir -p builder-scripts runner-scripts var/lib default-comfyui-bundle

              # Copy builder scripts
              cp -r ${./builder-scripts}/* builder-scripts/
              chmod +x builder-scripts/*.sh

              # Copy runner scripts
              cp -r ${./runner-scripts}/* runner-scripts/
              chmod +x runner-scripts/*.sh
            '';

            config = {
              Cmd = [ "${entrypointScript}/bin/entrypoint" ];
              WorkingDir = "/root";
              ExposedPorts = {
                "8188/tcp" = {};
              };
              Env = [
                "CLI_ARGS="
                "PYTHONUNBUFFERED=1"
                "PATH=/usr/bin:/bin:${python}/bin:${cudaPackages.cudatoolkit}/bin"
                "CUDA_HOME=${cudaPackages.cudatoolkit}"
                "LD_LIBRARY_PATH=${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudnn}/lib"
              ];
              Volumes = {
                "/root" = {};
              };
            };

            maxLayers = 100;
          };

          default = self.packages.${system}.comfyui;
        };

        apps = {
          build = {
            type = "app";
            program = toString (pkgs.writeScript "build-comfyui" ''
              #!${pkgs.bash}/bin/bash
              nix build .#comfyui
              ./result | docker load
            '');
          };

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
