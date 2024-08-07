{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  poetry-core,
  textfsm,
  invoke,
  pytestCheckHook,
  ruamel-yaml,
  toml,
  yamllint,
}:

buildPythonPackage rec {
  pname = "ntc-templates";
  version = "5.1.0";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "networktocode";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-SnmI1/lB1p/zldgn9jIid4yJ5+ubr5mh/IAqXY/1Wbc=";
  };

  nativeBuildInputs = [ poetry-core ];

  propagatedBuildInputs = [ textfsm ];

  nativeCheckInputs = [
    invoke
    pytestCheckHook
    ruamel-yaml
    toml
    yamllint
  ];

  # https://github.com/networktocode/ntc-templates/issues/743
  disabledTests = [
    "test_raw_data_against_mock"
    "test_verify_parsed_and_reference_data_exists"
  ];

  meta = with lib; {
    description = "TextFSM templates for parsing show commands of network devices";
    homepage = "https://github.com/networktocode/ntc-templates";
    changelog = "https://github.com/networktocode/ntc-templates/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
