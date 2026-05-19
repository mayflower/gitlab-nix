{ ... }:
{
  imports = [
    ./nixos/modules/services/misc/gitlab-nix.nix
    ./nixos/modules/services/continuous-integration/gitlab-nix-runner.nix
  ];
}
