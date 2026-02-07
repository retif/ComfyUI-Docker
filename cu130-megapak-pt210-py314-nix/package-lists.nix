# Organized package lists for layered builds
# This file defines package groups that match the Dockerfile installation order

{ python
, ps  # python.pkgs
, torchPackages
, pak3Packages ? {}
, pak5Packages ? {}
, pak7Packages ? {}
}:

rec {
  # Build tools (Layer 2)
  buildTools = with ps; [
    pip setuptools wheel packaging build
  ];

  # PyTorch (Layer 4)
  pytorch = with ps; [
    torchPackages.torch
    torchvision
    torchPackages.torchaudio
  ];

  # pak3 - Essentials (Layer 5)
  pak3 = with ps; [
    # Core ML frameworks
    pak3Packages.accelerate
    pak3Packages.diffusers
    huggingface-hub
    transformers

    # Scientific computing
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

    # Data formats
    pyyaml omegaconf onnx

    # System utilities
    joblib psutil tqdm regex
    pak3Packages.nvidia-ml-py

    # Additional
    pak3Packages.ftfy
  ];

  # CuPy (Layer 6)
  cupy = [
    torchPackages.cupy-cuda13x
  ];

  # pak5 - Extended libraries (Layer 7)
  pak5 = with ps; [
    # HTTP/networking
    aiohttp requests urllib3

    # Data processing
    albumentations av einops numba numexpr

    # ML/AI tools
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

    # Geometry and visualization
    shapely trimesh

    # Color and QR codes
    webcolors qrcode

    # Additional utilities
    yarl tomli pycocotools
  ];

  # pak7 - Face analysis + git packages (Layer 8)
  pak7 = with ps; [
    dlib
    pak7Packages.facexlib
    pak7Packages.insightface
    pak7Packages.clip
    pak7Packages.cozy-comfyui
    pak7Packages.cozy-comfy
    pak7Packages.cstr
    pak7Packages.ffmpy
    pak7Packages.img2texture
  ];

  # Performance libraries (Layer 10)
  performance = [
    torchPackages.flash-attn
    torchPackages.sageattention
    torchPackages.nunchaku
  ];

  # Cumulative lists (all packages up to a given layer)
  allUpToPyTorch = buildTools ++ pytorch;
  allUpToPak3 = buildTools ++ pytorch ++ pak3;
  allUpToCupy = buildTools ++ pytorch ++ pak3 ++ cupy;
  allUpToPak5 = buildTools ++ pytorch ++ pak3 ++ cupy ++ pak5;
  allUpToPak7 = buildTools ++ pytorch ++ pak3 ++ cupy ++ pak5 ++ pak7;
  allUpToPerformance = buildTools ++ pytorch ++ pak3 ++ cupy ++ pak5 ++ pak7 ++ performance;

  # Alias for convenience
  all = allUpToPerformance;
}
