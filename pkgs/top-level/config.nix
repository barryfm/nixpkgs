# This file defines the structure of the `config` nixpkgs option.

# This file is tested in `pkgs/test/config.nix`.
# Run tests with:
#
#     nix-build -A tests.config
#

{ config, lib, ... }:

let
  inherit (lib)
    literalExpression
    mapAttrsToList
    mkEnableOption
    mkOption
    optionals
    types
    ;

  mkMassRebuild =
    args:
    mkOption (
      builtins.removeAttrs args [ "feature" ]
      // {
        type = args.type or (types.uniq types.bool);
        default = args.default or false;
        description = (
          (args.description or ''
            Whether to ${args.feature} while building nixpkgs packages.
          ''
          )
          + ''
            Changing the default may cause a mass rebuild.
          ''
        );
      }
    );

  options = {

    # Internal stuff

    # Hide built-in module system options from docs.
    _module.args = mkOption { internal = true; };

    warnings = mkOption {
      type = types.listOf types.str;
      default = [ ];
      internal = true;
    };

    # Config options

    warnUndeclaredOptions = mkOption {
      description = "Whether to warn when `config` contains an unrecognized attribute.";
      type = types.bool;
      default = false;
    };

    doCheckByDefault = mkMassRebuild { feature = "run `checkPhase` by default"; };

    strictDepsByDefault = mkMassRebuild { feature = "set `strictDeps` to true by default"; };

    structuredAttrsByDefault = mkMassRebuild {
      feature = "set `__structuredAttrs` to true by default";
    };

    enableParallelBuildingByDefault = mkMassRebuild {
      feature = "set `enableParallelBuilding` to true by default";
    };

    configurePlatformsByDefault = mkMassRebuild {
      feature = "set `configurePlatforms` to `[\"build\" \"host\"]` by default";
    };

    contentAddressedByDefault = mkMassRebuild {
      feature = "set `__contentAddressed` to true by default";
    };

    allowAliases = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to expose old attribute names for compatibility.

        The recommended setting is to enable this, as it
        improves backward compatibility, easing updates.

        The only reason to disable aliases is for continuous
        integration purposes. For instance, Nixpkgs should
        not depend on aliases in its internal code. Projects
        that aren't Nixpkgs should be cautious of instantly
        removing all usages of aliases, as migrating too soon
        can break compatibility with the stable Nixpkgs releases.
      '';
    };

    allowUnfree = mkOption {
      type = types.bool;
      default = false;
      # getEnv part is in check-meta.nix
      defaultText = literalExpression ''false || builtins.getEnv "NIXPKGS_ALLOW_UNFREE" == "1"'';
      description = ''
        Whether to allow unfree packages.

        See [Installing unfree packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree) in the NixOS manual.
      '';
    };

    allowUnfreePredicate = mkOption {
      type = types.functionTo types.bool;
      default = _: false;
      defaultText = literalExpression ''pkg: false'';
      example = literalExpression ''pkg: lib.hasPrefix "vscode" pkg.name'';
      description = ''
        A function that specifies whether a given unfree package may be permitted.
        Only takes effect if [`config.allowUnfree`](#opt-allowUnfree) is set to false.

        See [Installing unfree packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree) in the NixOS manual.
      '';
    };

    allowNonSource = mkEnableOption "" // {
      default = true;
      defaultText = literalExpression ''true && builtins.getEnv "NIXPKGS_ALLOW_NONSOURCE" != "0"'';
      description = ''
        Whether to allow non-source packages.
        Can be combined with `config.allowNonSourcePredicate`.
      '';
    };

    allowNonSourcePredicate = mkOption {
      type = types.functionTo types.bool;
      default = _: false;
      defaultText = literalExpression ''pkg: false'';
      example = literalExpression ''
        pkg:
        (lib.all (
          prov: prov.isSource || prov == lib.sourceTypes.binaryFirmware
        ) pkg.meta.sourceProvenance);
      '';
      description = ''
        A function that specifies whether a given non-source package may be permitted.
        Only takes effect if [`config.allowNonSource`](#opt-allowNonSource) is set to false.
      '';
    };

    allowBroken = mkOption {
      type = types.bool;
      default = false;
      # getEnv part is in check-meta.nix
      defaultText = literalExpression ''false || builtins.getEnv "NIXPKGS_ALLOW_BROKEN" == "1"'';
      description = ''
        Whether to allow broken packages.

        See [Installing broken packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-broken) in the NixOS manual.
      '';
    };

    allowUnsupportedSystem = mkOption {
      type = types.bool;
      default = false;
      # getEnv part is in check-meta.nix
      defaultText = literalExpression ''false || builtins.getEnv "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM" == "1"'';
      description = ''
        Whether to allow unsupported packages.

        See [Installing packages on unsupported systems](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unsupported-system) in the NixOS manual.
      '';
    };

    cudaSupport = mkMassRebuild {
      type = types.bool;
      default = false;
      feature = "build packages with CUDA support by default";
    };

    rocmSupport = mkMassRebuild {
      type = types.bool;
      default = false;
      feature = "build packages with ROCm support by default";
    };

    packageOverrides = mkOption {
      type = types.functionTo types.raw;
      default = lib.id;
      defaultText = literalExpression ''lib.id'';
      example = literalExpression ''
        pkgs: rec {
          foo = pkgs.foo.override { /* ... */ };
        };
      '';
      description = ''
        A function that takes the current nixpkgs instance (`pkgs`) as an argument
        and returns a modified set of packages.

        See [Modify packages via `packageOverrides`](#sec-modify-via-packageOverrides).
      '';
    };

    showDerivationWarnings = mkOption {
      type = types.listOf (types.enum [ "maintainerless" ]);
      default = [ ];
      description = ''
        Which warnings to display for potentially dangerous
        or deprecated values passed into `stdenv.mkDerivation`.

        A list of warnings can be found in
        [/pkgs/stdenv/generic/check-meta.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/check-meta.nix).

        This is not a stable interface; warnings may be added, changed
        or removed without prior notice.
      '';
    };

    checkMeta = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to check that the `meta` attribute of derivations are correct during evaluation time.
      '';
    };
  };

in
{

  freeformType =
    let
      t = types.lazyAttrsOf types.raw;
    in
    t
    // {
      merge =
        loc: defs:
        let
          r = t.merge loc defs;
        in
        r // { _undeclared = r; };
    };

  inherit options;

  config = {
    warnings = optionals config.warnUndeclaredOptions (
      mapAttrsToList (k: v: "undeclared Nixpkgs option set: config.${k}") config._undeclared or { }
    );
  };

}
