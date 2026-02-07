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
    propagatedBuildInputs = with pythonPackages; [ numpy pyyaml psutil ];
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
      hash = "sha256-fHDrUyAVzS+a21PxAftseUWYjQI6CF0SfRVz3EndAIM=";
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
      hash = "sha256-7ksJGQJtjFM662mxbG7EqJGi9oRO+qFBIb9og4dTIJw=";
    };
    format = "wheel";
    propagatedBuildInputs = with pythonPackages; [ numpy ];
  };

  opencv-contrib-python-headless = pythonPackages.buildPythonPackage rec {
    pname = "opencv-contrib-python-headless";
    version = "4.10.0.84";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-vpHGyB6DlhPG87FXVb9xeJg5KJ0ONED6sJPgcIUW/88=";
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
      hash = "sha256-G4FrTEWHinNTGlAKRtv2HmRux6dJv4pN16WDOgTiiAg=";
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
      hash = "sha256-qExzqexWCm40fbonFuoazM9xmHrvreAriCzIncCg7iE=";
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
      hash = "sha256-pQjN2HdmztqvVaQZgSv59JOv+P/8AswZ31qOLnzLlCo=";
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
      hash = "sha256-widkhrAvDxuQvhVfLIukqOGU1Cd1eG22IvrM1lLY6Aw=";
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
      hash = "sha256-/qNxyU1j44phHBe7uF/kAOnI3bnoaEqc0OR3hqS8PHM=";
    };
  };
}
