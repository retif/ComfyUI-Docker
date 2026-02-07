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

  # Import our custom packages
  customPythonPackages = pkgs.callPackage ./python-packages.nix {
    inherit python;
    pythonPackages = python.pkgs;
    buildPythonPackage = python.pkgs.buildPythonPackage;
    fetchFromGitHub = pkgs.fetchFromGitHub;
    fetchurl = pkgs.fetchurl;
    cudaPackages = pkgs.cudaPackages_13_0 or pkgs.cudaPackages_12;
  };

  # This is the same list as in flake.nix
  packageList = with python.pkgs; [
    # Build tools
    pip setuptools wheel packaging build

    # PyTorch
    customPythonPackages.torch
    torchvision
    customPythonPackages.torchaudio

    # Performance
    customPythonPackages.flash-attn
    customPythonPackages.sageattention
    customPythonPackages.nunchaku
    customPythonPackages.cupy-cuda13x

    # Git packages
    customPythonPackages.clip
    customPythonPackages.cozy-comfyui
    customPythonPackages.cozy-comfy
    customPythonPackages.cstr
    customPythonPackages.ffmpy
    customPythonPackages.img2texture

    # Core ML
    customPythonPackages.accelerate
    customPythonPackages.diffusers
    huggingface-hub
    transformers

    # Scientific
    numpy scipy pillow imageio scikit-learn scikit-image matplotlib pandas

    # Computer vision
    opencv4
    customPythonPackages.opencv-contrib-python
    customPythonPackages.opencv-contrib-python-headless
    customPythonPackages.kornia

    # ML utilities
    customPythonPackages.timm
    customPythonPackages.torchmetrics
    customPythonPackages.compel
    customPythonPackages.lark
    customPythonPackages.spandrel

    # Data formats
    pyyaml omegaconf onnx

    # System utilities
    joblib psutil tqdm regex
    customPythonPackages.nvidia-ml-py

    # HTTP/networking
    aiohttp requests urllib3

    # Data processing
    albumentations av einops numba numexpr

    # ML/AI
    peft safetensors sentencepiece tokenizers

    # Utilities
    customPythonPackages.addict
    cachetools chardet filelock
    customPythonPackages.loguru
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
    customPythonPackages.facexlib
    customPythonPackages.insightface

    # Additional from python-packages.nix
    customPythonPackages.ftfy
  ];

in {
  count = builtins.length packageList;
  packages = builtins.map (p: p.pname or p.name or "unknown") packageList;
}
