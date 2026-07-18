{
  buildGoModule,
  lib,
  fetchFromGitLab,
  versionCheckHook,
}:

buildGoModule (finalAttrs: {
  pname = "gitlab-kas";
  version = "18.11.7";

  # nixpkgs-update: no auto update
  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "cluster-integration/gitlab-agent";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6o1fi0AjQNTi/fBjhmiciFJPstRGS2JEMl3QCQJIv1s=";
  };

  vendorHash = "sha256-ZhtUUIF1WiJidi00+EjvJMwLdUqRgJuNlgNiNdGJPGk=";
  subPackages = [ "./cmd/kas" ];

  ldflags =
    let
      goPkgPath = "gitlab.com/gitlab-org/cluster-integration/gitlab-agent/v${lib.versions.major finalAttrs.version}";
    in
    [
      "-X ${goPkgPath}/internal/cmd.Version=${finalAttrs.version}"
      "-X ${goPkgPath}/internal/cmd.GitRef=v${finalAttrs.version}"
    ];

  nativeInstallCheckHooks = [
    versionCheckHook
  ];

  meta = {
    description = "Kubernetes Agent (Gitlab side)";
    mainProgram = "kas";
    homepage = "https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent";
    changelog = "https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = [
      lib.maintainers.leona
    ];
  };
})
