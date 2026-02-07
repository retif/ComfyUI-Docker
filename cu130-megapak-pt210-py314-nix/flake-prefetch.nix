{
  description = "ComfyUI Docker Image - CUDA 13.0 with Python 3.14 (pre-fetched wheels)";

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
        # Pre-fetch PyTorch wheels (outside VM, reproducible)
        #########################################################################
        torchWheel = pkgs.fetchurl {
          url = "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl";
          sha256 = ""; # TODO: Fill in after first fetch
        };

        torchvisionWheel = pkgs.fetchurl {
          url = "https://download.pytorch.org/whl/cu130/torchvision-0.20.0%2Bcu130-cp314-cp314-linux_x86_64.whl";
          sha256 = ""; # TODO: Fill in after first fetch
        };

        torchaudioWheel = pkgs.fetchurl {
          url = "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-linux_x86_64.whl";
          sha256 = ""; # TODO: Fill in after first fetch
        };

        flashAttnWheel = pkgs.fetchurl {
          url = "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl";
          sha256 = ""; # TODO: Fill in after first fetch
        };

        sageattentionWheel = pkgs.fetchurl {
          url = "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl";
          sha256 = ""; # TODO: Fill in after first fetch
        };

        nunchakuWheel = pkgs.fetchurl {
          url = "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl";
          sha256 = ""; # TODO: Fill in after first fetch
        };

        #########################################################################
        # Base environment
        #########################################################################
        baseEnv = pkgs.buildEnv {
          name = "base-env";
          ignoreCollisions = true;
          paths = with pkgs; [
            bash coreutils findutils gnugrep gnused gnutar gzip which
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            gcc cmake ninja git
            ffmpeg x264 x265
            aria2 vim fish
          ];
        };

        #########################################################################
        # Python environment with pre-fetched wheels
        #########################################################################
        pythonEnv = python.withPackages (ps: with ps; [
          pip setuptools wheel packaging
        ]);

        #########################################################################
        # Final image using streamLayeredImage (no VM!)
        #########################################################################
        finalImage = pkgs.dockerTools.streamLayeredImage {
          name = "comfyui-boot";
          tag = "cu130-megapak-py314-nix";

          contents = [ baseEnv pythonEnv ];

          # Use fakeRootCommands instead of runAsRoot (no VM!)
          fakeRootCommands = ''
            # Create directories
            mkdir -p /builder-scripts /runner-scripts /default-comfyui-bundle /tmp/wheels

            # Copy pre-fetched wheels
            cp ${torchWheel} /tmp/wheels/torch.whl
            cp ${torchvisionWheel} /tmp/wheels/torchvision.whl
            cp ${torchaudioWheel} /tmp/wheels/torchaudio.whl
            cp ${flashAttnWheel} /tmp/wheels/flash_attn.whl
            cp ${sageattentionWheel} /tmp/wheels/sageattention.whl
            cp ${nunchakuWheel} /tmp/wheels/nunchaku.whl

            # Copy scripts
            cp -r ${./builder-scripts}/* /builder-scripts/
            cp -r ${./runner-scripts}/* /runner-scripts/
            chmod +x /builder-scripts/*.sh /runner-scripts/*.sh

            # Install PyTorch from local wheels (no network!)
            ${pythonEnv}/bin/pip install --no-cache-dir --no-index --find-links /tmp/wheels \
              torch torchvision torchaudio

            # Install dependencies
            ${pythonEnv}/bin/pip install --no-cache-dir -r /builder-scripts/pak3.txt
            ${pythonEnv}/bin/pip install --no-cache-dir -r /builder-scripts/pak5.txt
            ${pythonEnv}/bin/pip install --no-cache-dir -r /builder-scripts/pak7.txt

            # Install performance wheels from local files
            ${pythonEnv}/bin/pip install --no-cache-dir --no-index --find-links /tmp/wheels \
              flash_attn sageattention nunchaku

            # Setup ComfyUI
            cd /default-comfyui-bundle
            bash /builder-scripts/preload-cache.sh

            # Install ComfyUI requirements
            ${pythonEnv}/bin/pip install --no-cache-dir \
              -r /default-comfyui-bundle/ComfyUI/requirements.txt \
              -r /default-comfyui-bundle/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt

            # Cleanup
            rm -rf /tmp/wheels

            # List installed packages
            ${pythonEnv}/bin/pip list
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

      in {
        packages = {
          comfyui = finalImage;
          default = finalImage;
        };
      }
    );
}

# NOTE: To fill in the sha256 hashes:
# 1. Set sha256 = ""; (empty string)
# 2. Run: nix build .#comfyui
# 3. Copy the expected hash from error message
# 4. Repeat for each wheel
#
# Or use: nix-prefetch-url <url>
