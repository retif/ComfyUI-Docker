# Custom Python packages from pak3.txt (Essentials)
# Packages that need custom definitions (not in nixpkgs or need specific versions)

{ pkgs
, python
, pythonPackages
, fetchurl
, buildPythonPackage
}:

rec {
  #########################################################################
  # CORE ML FRAMEWORKS
  #########################################################################

  accelerate = pythonPackages.buildPythonPackage rec {
    pname = "accelerate";
    version = "1.2.1";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-A+Fh/GnUldryubXI1bQ9BuIUVSDARye1vaVtSfGkOrU=";
    };
    propagatedBuildInputs = with pythonPackages; [ numpy pyyaml psutil huggingface-hub safetensors ];
    doCheck = false;  # Skip runtime check - torch will be available in final image
  };

  diffusers = pythonPackages.buildPythonPackage rec {
    pname = "diffusers";
    version = "0.31.0";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-sdAac+RdQ6BjDCmRc5Fd3dafxQ8q6PKrXeT9JF6u1y8=";
    };
    propagatedBuildInputs = with pythonPackages; [
      numpy pillow requests regex
      huggingface-hub safetensors
    ];
  };

  ftfy = pythonPackages.buildPythonPackage rec {
    pname = "ftfy";
    version = "6.3.1";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-mzw9kPhPsmf+ZNN1oHt/iRLYF8+GAJrhNKoD4YGVBuw=";
    };
    propagatedBuildInputs = with pythonPackages; [ wcwidth ];
  };

  #########################################################################
  # COMPUTER VISION
  #########################################################################

  opencv-contrib-python = pythonPackages.buildPythonPackage rec {
    pname = "opencv-contrib-python";
    version = "4.10.0.84";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-Sj6uDtnK3xq+kpOmk4olpUDi/W1/wwhZXKpYlsizagw=";
    };
    format = "wheel";
    propagatedBuildInputs = with pythonPackages; [ numpy ];
  };

  opencv-contrib-python-headless = pythonPackages.buildPythonPackage rec {
    pname = "opencv-contrib-python-headless";
    version = "4.10.0.84";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-Y1ElDbl+H5HzGv3sJDavsciVlOPaAoUeDwHiDqFrvZ4=";
    };
    format = "wheel";
    propagatedBuildInputs = with pythonPackages; [ numpy ];
  };

  kornia = pythonPackages.buildPythonPackage rec {
    pname = "kornia";
    version = "0.7.4";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-H43WJoylovLsBLE8SNpN+5C6LPrn4x4MyA039lIPo/E=";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };

  #########################################################################
  # ML UTILITIES
  #########################################################################

  timm = pythonPackages.buildPythonPackage rec {
    pname = "timm";
    version = "1.0.17";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-kMzweJTWrjglm3qnyU1oMAL142D9Q0cchPnabDr7ig0=";
    };
    propagatedBuildInputs = with pythonPackages; [ pyyaml huggingface-hub ];
  };

  torchmetrics = pythonPackages.buildPythonPackage rec {
    pname = "torchmetrics";
    version = "1.6.0";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-rruiSHCPuQ3vIMzLpvVb3dE0pY3kP7IrDFyg86ifqYQ=";
    };
    propagatedBuildInputs = with pythonPackages; [ numpy ];
    doCheck = false;  # Avoid circular dependencies with torch
  };

  compel = pythonPackages.buildPythonPackage rec {
    pname = "compel";
    version = "2.0.3";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-ZUi5A0AWa4XibT1bTpoR3mkIoDtrJIea/2Xm5vxbZ3w=";
    };
    propagatedBuildInputs = with pythonPackages; [ transformers ];
  };

  lark = pythonPackages.buildPythonPackage rec {
    pname = "lark";
    version = "1.2.2";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-yoB9AWLNFs7xWo/uy4YtcxnnoJvbE675J5aORQQP7YA=";
    };
  };

  #########################################################################
  # SYSTEM UTILITIES
  #########################################################################

  nvidia-ml-py = pythonPackages.buildPythonPackage rec {
    pname = "nvidia-ml-py";
    version = "12.560.30";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-8CVNx0AGR2gKBy7gJQm/1GECtgvf7KMhV21NSBfn/pc=";
    };
  };
}
