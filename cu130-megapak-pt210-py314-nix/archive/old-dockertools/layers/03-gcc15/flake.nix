{
  description = "Layer 3: GCC 15";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    layer02.url = "path:../02-python-tools";
  };

  outputs = { self, nixpkgs, layer02 }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };

      # GCC 15 (or latest available)
      # In nixpkgs, gcc is usually the latest stable version
      # For specific GCC 15, we use gcc from unstable
      gcc15 = pkgs.gcc;

    in {
      packages.${system} = {
        default = pkgs.dockerTools.buildImage {
          name = "comfyui-layer03-gcc15";
          tag = "cu130-megapak-py314-nix";
          fromImage = layer02.packages.${system}.default;

          contents = pkgs.buildEnv {
            name = "gcc15-env";
            paths = [
              gcc15
              pkgs.binutils
            ];
          };

          config = {
            Env = [
              "CC=${gcc15}/bin/gcc"
              "CXX=${gcc15}/bin/g++"
              "CPP=${gcc15}/bin/cpp"
            ];
          };
        };
      };
    };
}
