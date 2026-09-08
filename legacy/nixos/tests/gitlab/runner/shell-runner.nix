{
  runnerConfig,
}:
# This is the runner config for the `nixosConfiguration.services.gitlab-nix-runner.services.X`
{
  services.gitlab-nix-runner.services.shell-runner = {
    description = runnerConfig.desc;
    authenticationTokenConfigFile = runnerConfig.tokenFile;

    executor = "shell";
  };
}
