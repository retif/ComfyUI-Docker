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
      hash = "sha256-21pheRt9o8GqWkluZM1y29TvPvLLtpaA/UXcJVsNovM=";
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
      hash = "sha256-vEeA/+5uaBLRnmL8BkZrExgH3jsgP6E8ThJcyBuwBRE=";
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
      hash = "sha256-xL7RNl3n6E67TqFmch8ul2bIfwsxk6iGLvVBGViNQO4=";
    };
    propagatedBuildInputs = [ torch ];
  };

  sageattention = buildWheel {
    pname = "sageattention";
    version = "2.2.0+cu130torch2.10.0";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl";
      hash = "sha256-EoEL3OUFb5l5EdQkGuCcPIroj553t90eceITV2lLDV4=";
      name = "sageattention-2.2.0-cu130torch2.10.0-cp314-cp314-linux_x86_64.whl";
    };
    propagatedBuildInputs = [ torch ];
  };

  nunchaku = buildWheel {
    pname = "nunchaku";
    version = "1.0.2+torch2.10";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl";
      hash = "sha256-ZHfRivrIQ07U0VdRWYttE+rQe1JjCTUDZjeMSvovFkw=";
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
      hash = "sha256-ufNW9EFzbW6LgHLg3Np5YXab7JltKAOImKAzp00GfyA=";
    };
    propagatedBuildInputs = [ pythonPackages.numpy ];
  };
}
