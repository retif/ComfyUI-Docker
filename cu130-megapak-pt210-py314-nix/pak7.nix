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
      hash = "sha256-eueEpSDrUuBVg+i/n2j3f0UIMjmsdU1kbWNQF7Sed2M=";
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
      hash = "sha256-8ZH3GWEuuzcBj0GTaBRQBUTND4bm/NZ2wCPzVMZo3fc=";
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
      hash = "sha256-+urF5nYnGQi+s69du51ckUPLAw19kTsOt+ngVr9pX5I=";
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
      hash = "sha256-wzLZ+G7Pz2xh7UXYKwQMZjFcTpbWcPeEwKSotRwOLjc=";
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
      hash = "sha256-iDwWPDT6J4n6toE/8fmC+l9I2nroN5tv0Q9urZDe/b8=";
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
      hash = "sha256-H4OfPD54n4n2lPR9MMnHzHyO7fBXao/6tQzpD/74xjs=";
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
      hash = "sha256-96iaH4jDELeyokJf5dlqgusm3HON1fXXPyiBk1H1rCI=";
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
      hash = "sha256-58me9Rng+hy1ntUBJ8cUVVrk+CEFgmW/ATnzYk7N8U4=";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };
}
