# List all packages in pythonWithAllPackages
# Usage: nix eval --json -f list-packages.nix
let
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  };

  python = pkgs.python314;

  # Import our modular custom packages
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
    inherit python;
    pythonPackages = python.pkgs;
    buildPythonPackage = python.pkgs.buildPythonPackage;
    fetchurl = pkgs.fetchurl;
    cudaPackages = pkgs.cudaPackages_13_0;
  };

  # This is the same list as in flake.nix
  packageList = with python.pkgs; [
    # Build tools
    pip setuptools wheel packaging build

    # PyTorch
    customPackages.torch
    torchvision
    customPackages.torchaudio

    # Performance
    customPackages.flash-attn
    customPackages.sageattention
    customPackages.nunchaku
    customPackages.cupy-cuda13x

    # Git packages
    pak7Packages.clip
    pak7Packages.cozy-comfyui
    pak7Packages.cozy-comfy
    pak7Packages.cstr
    pak7Packages.ffmpy
    pak7Packages.img2texture

    # Core ML
    pak3Packages.accelerate
    pak3Packages.diffusers
    huggingface-hub
    transformers

    # Scientific
    numpy scipy pillow imageio scikit-learn scikit-image matplotlib pandas

    # Computer vision
    opencv4
    pak3Packages.opencv-contrib-python
    pak3Packages.opencv-contrib-python-headless
    pak3Packages.kornia

    # ML utilities
    pak3Packages.timm
    pak3Packages.torchmetrics
    pak3Packages.compel
    pak3Packages.lark
    pak5Packages.spandrel

    # Data formats
    pyyaml omegaconf onnx

    # System utilities
    joblib psutil tqdm regex
    pak3Packages.nvidia-ml-py

    # HTTP/networking
    aiohttp requests urllib3

    # Data processing
    albumentations av einops numba numexpr

    # ML/AI
    peft safetensors sentencepiece tokenizers

    # Utilities
    pak5Packages.addict
    cachetools chardet filelock
    pak5Packages.loguru
    protobuf pydantic pydub rich toml typing-extensions

    # Version control
    gitpython

    # Database
    sqlalchemy

    # Geometry
    shapely trimesh

    # Color/QR
    webcolors qrcode

    # Additional
    yarl tomli pycocotools

    # Face analysis
    dlib
    pak7Packages.facexlib
    pak7Packages.insightface

    # Additional from python-packages.nix
    pak3Packages.ftfy
  ];

in {
  count = builtins.length packageList;
  packages = builtins.map (p: p.pname or p.name or "unknown") packageList;
}
