# Custom Python packages from pak7.txt (Face Analysis + Git Packages)
# Face detection/recognition libraries and packages built from git

{ pkgs
, python
, pythonPackages
, fetchFromGitHub
, buildPythonPackage
}:

let
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
  # FACE ANALYSIS
  #########################################################################

  facexlib = pythonPackages.buildPythonPackage rec {
    pname = "facexlib";
    version = "0.3.0";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "0y5804y68hh55fz78baaf8j2mbfgiihyzcz82v321f1p2n35hp94";
    };
    propagatedBuildInputs = with pythonPackages; [ numpy pillow opencv4 ];
  };

  insightface = pythonPackages.buildPythonPackage rec {
    pname = "insightface";
    version = "0.7.3";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "1xyxd3359wr3q1vddz76hq7wsi05a0a6i4s1iw0kgfrfc4czg4gi";
    };
    propagatedBuildInputs = with pythonPackages; [ numpy opencv4 ];
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
      sha256 = "14jzd6zmdq79nw73p4bx1l1wnhwibjfvnpdgnfz0h697fvkcbsps";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };

  cozy-comfyui = buildFromGit {
    pname = "cozy-comfyui";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "cozy-comfyui";
      repo = "cozy_comfyui";
      rev = "main";
      sha256 = "0drf1qfbba54q22gfw6njr75qcb61h22pn25xmhnrkygdvwdjcn3";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };

  cozy-comfy = buildFromGit {
    pname = "cozy-comfy";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "cozy-comfyui";
      repo = "cozy_comfy";
      rev = "main";
      sha256 = "1gzxvs8asvhgs5prndz8gbd4hpzshbwz2gw1nvx8j9zs6hy1cg48";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };

  cstr = buildFromGit {
    pname = "cstr";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "ltdrdata";
      repo = "cstr";
      rev = "main";
      sha256 = "0fy6z3z0zs8cnpx8ysjpy3nqwz6cqz4k0zgljkv8k7vq7qy9z0qz";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };

  ffmpy = buildFromGit {
    pname = "ffmpy";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "ltdrdata";
      repo = "ffmpy";
      rev = "f000737698b387ffaeab7cd871b0e9185811230d";
      sha256 = "08mcym8r70987zbzbmcdfgf2dsw2dbcyaps2larbf463i0grma7p";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };

  img2texture = buildFromGit {
    pname = "img2texture";
    version = "unstable-2024-01-01";
    src = fetchFromGitHub {
      owner = "ltdrdata";
      repo = "img2texture";
      rev = "d6159abea44a0b2cf77454d3d46962c8b21eb9d3";
      sha256 = "0kpirm765wrr06znb0h547wf8njm2k3jf0fmkssiryp037srxjg7";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };
}
