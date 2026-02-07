{
  description = "Layer 1: Base system + CUDA 13.0";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };

      cudaPackages = pkgs.cudaPackages_13_0;

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer01-base-cuda";
          tag = "cu130-megapak-py314-nix";

          contents = pkgs.buildEnv {
            name = "base-cuda-env";
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

          config = {
            Env = [
              "PATH=/usr/bin:/bin:${cudaPackages.cudatoolkit}/bin"
              "CUDA_HOME=${cudaPackages.cudatoolkit}"
              "LD_LIBRARY_PATH=${cudaPackages.cudatoolkit}/lib:${cudaPackages.cudnn}/lib"
            ];
          };
        };
      };
    };
}
