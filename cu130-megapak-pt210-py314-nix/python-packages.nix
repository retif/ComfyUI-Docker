# Custom Python package definitions for ComfyUI
# This file contains all packages that need to be built from wheels or source
# Packages available in nixpkgs are used directly in flake.nix

{ pkgs
, python
, pythonPackages
, fetchurl
, fetchFromGitHub
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

  # Helper to build from git
  buildFromGit = { pname, version, src, ... }@args:
    buildPythonPackage ({
      inherit pname version src;
      pyproject = true;
      build-system = with pythonPackages; [ setuptools ];
      doCheck = false;
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
      hash = "sha256-1wx21mdjbp25zn09ddnby8zfzm6vfb6n8vj9bamc38vx3dwn2nnv";
      name = "torch-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl";  # Decode %2B
    };
  };

  torchvision = buildWheel {
    pname = "torchvision";
    version = "0.20.0+cu130";
    src = fetchurl {
      url = "https://download.pytorch.org/whl/cu130/torchvision-0.20.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl";
      hash = "sha256-0000000000000000000000000000000000000000000000000000";
      name = "torchvision-0.20.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl";  # Decode %2B
    };
    propagatedBuildInputs = [ torch pythonPackages.pillow pythonPackages.numpy ];
  };

  torchaudio = buildWheel {
    pname = "torchaudio";
    version = "2.10.0+cu130";
    src = fetchurl {
      url = "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp314-cp314-manylinux_2_28_x86_64.whl";
      hash = "sha256-0485n0dwhp0j9qya2gr07gg0f60kdd30dz32kv8i4s3fxvzq0ixw";
      name = "torchaudio-2.10.0-cu130-cp314-cp314-manylinux_2_28_x86_64.whl";  # Decode %2B
    };
    propagatedBuildInputs = [ torch ];
  };

  #########################################################################
  # PERFORMANCE WHEELS (Custom built for Python 3.14)
  #########################################################################

  flash-attn = buildWheel {
    pname = "flash-attn";
    version = "2.8.2";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/flash-attn-v2.8.2-py314-torch2.10.0-cu130/flash_attn-2.8.2-cp314-cp314-linux_x86_64.whl";
      hash = "sha256-1vj0imc1jhgm5s3ai4ri1dzwhrlp5qgp4rm19sxlxs77blvd3gn4";
    };
    propagatedBuildInputs = [ torch ];
  };

  sageattention = buildWheel {
    pname = "sageattention";
    version = "2.2.0+cu130torch2.10.0";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/sageattention-v2.2.0-py314-torch2.10.0-cu130/sageattention-2.2.0%2Bcu130torch2.10.0-cp314-cp314-linux_x86_64.whl";
      hash = "sha256-0phd9dlmf4z2f4gdvdvpks7yi2iwkkh1l96l25wrjvq5wpf0p08j";
      name = "sageattention-2.2.0-cu130torch2.10.0-cp314-cp314-linux_x86_64.whl";  # Decode %2B to avoid Nix path errors
    };
    propagatedBuildInputs = [ torch ];
  };

  nunchaku = buildWheel {
    pname = "nunchaku";
    version = "1.0.2+torch2.10";
    src = fetchurl {
      url = "https://github.com/retif/pytorch-wheels-builder/releases/download/nunchaku-v1.0.2-py314-torch2.10.0-cu130/nunchaku-1.0.2%2Btorch2.10-cp314-cp314-linux_x86_64.whl";
      hash = "sha256-0k0n5zx4m31pcq1ka2b3a9xx1shkdn5mjlaps7a4why8za5d2xv4";
      name = "nunchaku-1.0.2-torch2.10-cp314-cp314-linux_x86_64.whl";  # Decode %2B to avoid Nix path errors
    };
    propagatedBuildInputs = [ torch ];
  };

  #########################################################################
  # GIT PACKAGES (Built from source)
  #########################################################################

  clip = buildFromGit {
    pname = "clip";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "openai";
      repo = "CLIP";
      rev = "main";
      sha256 = "sha256-14jzd6zmdq79nw73p4bx1l1wnhwibjfvnpdgnfz0h697fvkcbsps";
    };
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    propagatedBuildInputs = with pythonPackages; [ torch ftfy regex tqdm ];  # Removed torchvision dependency
  };

  cozy-comfyui = buildFromGit {
    pname = "cozy-comfyui";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "cozy-comfyui";
      repo = "cozy_comfyui";
      rev = "main";
      sha256 = "sha256-0b064j57qhivz8bnsjqbvd941h7c1d9rixdyahblrgdjlsj0w9nm";
    };
  };

  cozy-comfy = buildFromGit {
    pname = "cozy-comfy";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "cozy-comfyui";
      repo = "cozy_comfy";
      rev = "main";
      sha256 = "sha256-11kkcvy7jmqab4dj4y0983k8bylz89g331m9wli08qljzji5fm25";
    };
  };

  cstr = buildFromGit {
    pname = "cstr";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "ltdrdata";
      repo = "cstr";
      rev = "main";
      sha256 = "sha256-1fm22x63ijqszc3a38f7hdfglhbx16pwdkz8b9j5a81v966yf06d";
    };
  };

  ffmpy = buildFromGit {
    pname = "ffmpy";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "ltdrdata";
      repo = "ffmpy";
      rev = "main";
      sha256 = "sha256-08mcym8r70987zbzbmcdfgf2dsw2dbcyaps2larbf463i0grma7p";
    };
  };

  img2texture = buildFromGit {
    pname = "img2texture";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "ltdrdata";
      repo = "img2texture";
      rev = "main";
      sha256 = "sha256-0kpirm765wrr06znb0h547wf8njm2k3jf0fmkssiryp037srxjg7";
    };
  };

  #########################################################################
  # NOTE: SAM models (segment-anything, SAM2, SAM3) are pip packages
  # They are NOT built from source - custom nodes install them as needed
  # The segment-anything package is available via pip/nixpkgs
  #########################################################################

  #########################################################################
  # ADDITIONAL PYPI PACKAGES (not in nixpkgs or need specific versions)
  #########################################################################

  # Common dependencies
  ftfy = pythonPackages.buildPythonPackage rec {
    pname = "ftfy";
    version = "6.3.1";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = with pythonPackages; [ wcwidth ];
  };

  nvidia-ml-py = pythonPackages.buildPythonPackage rec {
    pname = "nvidia-ml-py";
    version = "12.560.30";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
  };

  # Computer Vision
  opencv-contrib-python = pythonPackages.buildPythonPackage rec {
    pname = "opencv-contrib-python";
    version = "4.10.0.84";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    format = "wheel";
    propagatedBuildInputs = with pythonPackages; [ numpy ];
  };

  opencv-contrib-python-headless = pythonPackages.buildPythonPackage rec {
    pname = "opencv-contrib-python-headless";
    version = "4.10.0.84";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    format = "wheel";
    propagatedBuildInputs = with pythonPackages; [ numpy ];
  };

  # ML/AI packages
  timm = pythonPackages.buildPythonPackage rec {
    pname = "timm";
    version = "1.0.17";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = [ torch pythonPackages.pyyaml pythonPackages.huggingface-hub ];
  };

  accelerate = pythonPackages.buildPythonPackage rec {
    pname = "accelerate";
    version = "1.2.1";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = with pythonPackages; [ numpy pyyaml psutil torch ];
  };

  diffusers = pythonPackages.buildPythonPackage rec {
    pname = "diffusers";
    version = "0.31.0";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = with pythonPackages; [
      numpy pillow requests regex
      huggingface-hub safetensors
    ];
  };

  torchmetrics = pythonPackages.buildPythonPackage rec {
    pname = "torchmetrics";
    version = "1.6.0";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = [ torch pythonPackages.numpy ];
  };

  kornia = pythonPackages.buildPythonPackage rec {
    pname = "kornia";
    version = "0.7.4";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = [ torch ];
  };

  # Utilities
  compel = pythonPackages.buildPythonPackage rec {
    pname = "compel";
    version = "2.0.3";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = [ torch pythonPackages.transformers ];
  };

  lark = pythonPackages.buildPythonPackage rec {
    pname = "lark";
    version = "1.2.2";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
  };

  spandrel = pythonPackages.buildPythonPackage rec {
    pname = "spandrel";
    version = "0.4.0";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = [ torch ];
  };

  # Face analysis
  insightface = pythonPackages.buildPythonPackage rec {
    pname = "insightface";
    version = "0.7.3";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = with pythonPackages; [ numpy opencv4 ];
  };

  facexlib = pythonPackages.buildPythonPackage rec {
    pname = "facexlib";
    version = "0.3.0";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
    propagatedBuildInputs = with pythonPackages; [ numpy pillow opencv4 torch torchvision ];
  };

  # Additional utilities from pak5.txt
  addict = pythonPackages.buildPythonPackage rec {
    pname = "addict";
    version = "2.4.0";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
  };

  loguru = pythonPackages.buildPythonPackage rec {
    pname = "loguru";
    version = "0.7.3";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-0000000000000000000000000000000000000000000000000000";  # TODO: prefetch
    };
  };

  #########################################################################
  # NOTE: Many packages from pak files are available in nixpkgs!
  # Check with: nix search nixpkgs python314Packages.<package>
  #
  # Available in nixpkgs (use directly in flake.nix):
  # - numpy, scipy, pillow, opencv4, scikit-learn, scikit-image
  # - matplotlib, pandas, transformers, huggingface-hub
  # - aiohttp, requests, urllib3, pyyaml, omegaconf
  # - einops, safetensors, sentencepiece, tokenizers
  # - cachetools, chardet, filelock, protobuf, pydantic
  # - rich, toml, typing-extensions, gitpython, sqlalchemy
  # - joblib, psutil, tqdm, regex
  #
  # Only add custom definitions here if:
  # 1. Not in nixpkgs
  # 2. Need specific version
  # 3. Need custom build flags
  #########################################################################
}
