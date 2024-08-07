{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  jinja2,
  ply,
  iverilog,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pyverilog";
  version = "1.3.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1a74k8r21swmfwvgv4c014y6nbcyl229fspxw89ygsgb0j83xnar";
  };

  disabled = pythonOlder "3.7";

  patchPhase = ''
    # The path to Icarus can still be overridden via an environment variable at runtime.
    substituteInPlace pyverilog/vparser/preprocessor.py \
      --replace "iverilog = 'iverilog'" "iverilog = '${iverilog}/bin/iverilog'"
  '';

  propagatedBuildInputs = [
    jinja2
    ply
    iverilog
  ];

  preCheck = ''
    substituteInPlace pytest.ini \
      --replace "python_paths" "pythonpath"
  '';

  nativeCheckInputs = [ pytestCheckHook ];

  meta = with lib; {
    homepage = "https://github.com/PyHDI/Pyverilog";
    description = "Python-based Hardware Design Processing Toolkit for Verilog HDL";
    license = licenses.asl20;
    maintainers = with maintainers; [ trepetti ];
  };
}
