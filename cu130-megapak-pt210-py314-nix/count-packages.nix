# Extract package list from flake.nix
let
  flake = builtins.getFlake (toString ./.);
  pythonEnv = flake.packages.x86_64-linux.pythonWithAllPackages;
in
  builtins.map (p: p.pname or p.name) pythonEnv.passthru.requiredPythonModules
