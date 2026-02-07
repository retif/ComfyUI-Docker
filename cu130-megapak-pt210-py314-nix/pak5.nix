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
      hash = "sha256-MaM8EMjh4QQiv9QxrrXTUcfPf6Zx48TfAEFiJksoIgw=";
    };
  };

  spandrel = pythonPackages.buildPythonPackage rec {
    pname = "spandrel";
    version = "0.4.0";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      hash = "sha256-gZ8/Ff6UT+WJ9DujMVBFigDQ7QwujvHu8BmGFTIBJ7E=";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };
}
