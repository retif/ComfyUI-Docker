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
      sha256 = "1pwdxvyfl2sl47cr8zcw9klql6sbjq9bhinyzg6yfdzqijavn75y";
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
      sha256 = "07qcsgw25bxvr4chs7wsk8pyyag2pvf9qr0779ygrazlcfp9ii6b";
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
      sha256 = "10q0vm4xqwqmgl95s21s0a6rhibrdkxh3wakvfd2zk8m419ynw3w";
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
      sha256 = "1710af3q6s5z450s3yjfhkva54d8qip6rcb9xcx5733d08chjjzf";
    };
    format = "wheel";
    propagatedBuildInputs = with pythonPackages; [ numpy ];
  };

  opencv-contrib-python-headless = pythonPackages.buildPythonPackage rec {
    pname = "opencv-contrib-python-headless";
    version = "4.10.0.84";
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "1kzz2s2p1q4kn3x40d0fkll3k63qf6zmamxiyg3175l33v4cd4dy";
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
      sha256 = "0248w823m0x5sx6qmgs9lz3nwr0yyvdlc2jh399p72l78m66p08v";
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
      sha256 = "08gfl309vj1ci0my1bgggac73kyc3bm1c9xsgls6w2jnxjlp6k58";
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
      sha256 = "0allrdy2x3jsvwcwq0pwzzwaz4zlz4mq26d4anpxmkk6fzccs255";
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
      sha256 = "0378v19ddk7s4av6sy3m4za99qd8lj5jqpqmps81n3rgn23689y2";
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
      sha256 = "0wrwpjj8cxz4s2f4ls78p7fwis80wigvifqp3ihqmqv39p4p38zy";
    };
  };
}
