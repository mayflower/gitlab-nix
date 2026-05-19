{
  description = "Nix flake for GitLab packages and modules.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/x86_64-linux";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-compat.url = "github:NixOS/flake-compat";
    flake-compat.flake = false;
  };

  outputs =
    inputs:
    let
      branch = (import ./branch.nix);
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (top: {
      systems = (import inputs.systems);
      flake = {
        overlays = {
          gitlab-nix = import ./${branch}/overlays.nix;
          default = top.config.flake.overlays.gitlab-nix;
        };
        nixosModules = {
          gitlab-nix = import ./${branch}/modules.nix;
          default = top.config.flake.nixosModules.gitlab-nix;
        };
      };
      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:
        let
          fmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
            programs.nixfmt.enable = true;
          };
        in
        {
          apps = {
            gitlab-nix-update = {
              type = "app";
              program = pkgs.writeShellScriptBin "gitlab-nix-update" ''
                REPO="$(${pkgs.git}/bin/git rev-parse --show-toplevel)" || exit 1
                cd "$(find "$REPO/${branch}" -name update.py -printf "%h")" || exit 1
                exec ./update.py "$@"
              '';
            };
          };
          devShells.default = pkgs.mkShellNoCC {
            inputsFrom = [ fmtEval.config.build.devShell ];
            packages = with pkgs; [
              dasel  # TOML driver for .claude/skills/* (DESIGN §16)
              jq
            ];
          };
          legacyPackages = pkgs;
          packages = lib.filterAttrs (_: lib.isDerivation) pkgs.gitlab-nix;
          checks = import ./${branch}/tests.nix { inherit pkgs; };
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              top.config.flake.overlays.gitlab-nix
            ];
          };
          formatter = fmtEval.config.build.wrapper;
        };
    });
}
