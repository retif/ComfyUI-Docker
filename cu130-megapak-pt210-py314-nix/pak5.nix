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
      sha256 = "0312515jcqj103gw9qvilrzwzisisfsswcflpwi09qg1r083r8ri";
    };
  };

  spandrel = pythonPackages.buildPythonPackage rec {
    pname = "spandrel";
    version = "0.4.0";
    pyproject = true;
    build-system = with pythonPackages; [ setuptools ];
    src = pythonPackages.fetchPypi {
      inherit pname version;
      sha256 = "1c9704r1b1hry3pg33if1knx004a8m8338rvyj4yakwlzqakz7w1";
    };
    propagatedBuildInputs = with pythonPackages; [ ];
  };
}
