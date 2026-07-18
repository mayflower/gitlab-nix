{ pkgs, ... }:
{
  gitlab-nix = pkgs.testers.runNixOSTest {
    imports = [ ./nixos/tests/gitlab/gitlab.nix ];
    defaults.imports = [ ./modules.nix ];
  };
  gitlab-nix-runner = pkgs.testers.runNixOSTest {
    imports = [ ./nixos/tests/gitlab/runner.nix ];
    defaults.imports = [ ./modules.nix ];
  };
}
