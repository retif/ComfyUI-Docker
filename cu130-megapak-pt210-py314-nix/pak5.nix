# Custom Python packages from pak5.txt (Utilities and Extensions)
# Packages that need custom definitions (not in nixpkgs or need specific versions)

{ pkgs
, python
, pythonPackages
, buildPythonPackage
}:

rec {
  #########################################################################
  # UTILITIES
  #########################################################################

  addict = pythonPackages.buildPythonPackage rec {
    pname = "addict";
    version = "2.4.0";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-s7IhDg4GeigfVkbIxduS6ZtyMeqLDrX3Tb354lnU5JQ=";
    };
  };

  loguru = pythonPackages.buildPythonPackage rec {
    pname = "loguru";
    version = "0.7.3";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-GUgFied9R7jYWyyCetldSb8xsNzeFlk4kutR3RhwbrY=";
    };
  };

  spandrel = pythonPackages.buildPythonPackage rec {
    pname = "spandrel";
    version = "0.4.0";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-9FUmiT+SOhLvN1QsROREsSCJdlk7x8zfpU/QTHw+gMo=";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };
}
