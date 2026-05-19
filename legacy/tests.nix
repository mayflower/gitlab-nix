{ pkgs, ... }:
{
  gitlab-nix = pkgs.testers.runNixOSTest {
    imports = [ ./nixos/tests/gitlab.nix ];
    defaults.imports = [ ./modules.nix ];
  };
}
