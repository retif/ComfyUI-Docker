# Custom Python packages NOT in pak files
# PyTorch wheels, performance libraries, and additional packages

{ pkgs
, python
, pythonPackages
, fetchurl
, buildPythonPackage
, cudaPackages
}:

let
  # Helper to build from wheel
  buildWheel = { pname, version, src, ... }@args:
    buildPythonPackage ({
      inherit pname version src;
      format = "wheel";
      dontBuild = true;
      dontUsePipInstall = false;
    } // builtins.removeAttrs args [ "pname" "version" "src" ]);

in rec {
  #########################################################################
  # PYTORCH WHEELS (Official CUDA 13.0 builds)
  #########################################################################

  torch = buildWheel {
    pname = "torch";
    version = "2.10.0+cu130";
    src = fetchurl {
      url = "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl";
      sha256 = "1wx21mdjbp25zn09ddnby8zfzm6vfb6n8vj9bamc38vx3dwn2nnv";
      name = "torch-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl";
    };
  };

  # Note: torchvision available in nixpkgs, using that instead
  # torchvision wheel has Access Denied from PyTorch CDN

  torchaudio = buildWheel {
    pname = "torchaudio";
    version = "2.10.0+cu130";
    src = fetchurl {
      url = "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl";
      sha256 = "0485n0dwhp0j9qya2gr07gg0f60kdd30dz32kv8i4s3fxvzq0ixw";
      name = "torchaudio-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl";
    };
    propagatedBuildInputs = [ torch ];
  };

  #########################################################################
  # PERFORMANCE LIBRARIES (Custom builds for Python 3.14)
  #########################################################################

  flash-attn = buildWheel {
    pname = "flash-attn";
    version = "2.8.2";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl";
      sha256 = "1vj0imc1jhgm5s3ai4ri1dzwhrlp5qgp4rm19sxlxs77blvd3gn4";
    };
    propagatedBuildInputs = [ torch ];
  };

  sageattention = buildWheel {
    pname = "sageattention";
    version = "2.2.0+cu130torch2.10.0";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl";
      sha256 = "0phd9dlmf4z2f4gdvdvpks7yi2iwkkh1l96l25wrjvq5wpf0p08j";
      name = "sageattention-2.2.0-cu130torch2.10.0-cp314-cp314-linux_x86_64.whl";
    };
    propagatedBuildInputs = [ torch ];
  };

  nunchaku = buildWheel {
    pname = "nunchaku";
    version = "1.0.2+torch2.10";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl";
      sha256 = "0k0n5zx4m31pcq1ka2b3a9xx1shkdn5mjlaps7a4why8za5d2xv4";
      name = "nunchaku-1.0.2-torch2.10-cp314-cp314-linux_x86_64.whl";
    };
    propagatedBuildInputs = [ torch ];
  };

  #########################################################################
  # CUDA PACKAGES (Python 3.14 pre-release)
  #########################################################################

  cupy-cuda13x = buildWheel {
    pname = "cupy-cuda13x";
    version = "14.0.0rc1";
    src = fetchurl {
      url = "https://github.com/cupy/cupy/releases/download/v14.0.0rc1/cupy_cuda13x-14.0.0rc1-cp314-cp314-manylinux2014_x86_64.whl";
      sha256 = "083z0r6sfcx0k2406a3dk7n9nxk1g7ddrq3jh25nwvbk87s5dwxr";
    };
    propagatedBuildInputs = [ pythonPackages.numpy ];
  };
}
