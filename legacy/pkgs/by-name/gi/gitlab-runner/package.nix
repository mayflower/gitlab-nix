{
  lib,
  stdenv,
  bash,
  buildGoModule,
  fetchFromGitLab,
  gitMinimal,
  nix-update-script,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

buildGoModule (finalAttrs: {
  pname = "gitlab-runner";
  version = "19.3.2";

  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "gitlab-runner";
    tag = "v${finalAttrs.version}";
    hash = "sha256-c9Ize6TlhlBUS6+KRulqPdqxCnxYDF4YKOpdinOvtHs=";
  };

  vendorHash = "sha256-wuzVFCBOr3Lkh+d8yTvSXKrgv2HzIIRFBSaIO34EvQQ=";

  # For patchShebangs
  buildInputs = [ bash ];

  patches = [
    ./fix-shell-path.patch
    ./remove-bash-test.patch
  ];

  prePatch = ''
    # Remove some tests that can't work during a nix build

    # Needs the build directory to be a git repo
    substituteInPlace commands/helpers/file_archiver_test.go \
      --replace-fail "func TestCacheArchiverAddingUntrackedFiles" "func OFF_TestCacheArchiverAddingUntrackedFiles" \
      --replace-fail "func TestCacheArchiverAddingUntrackedUnicodeFiles" "func OFF_TestCacheArchiverAddingUntrackedUnicodeFiles"

    # Needs `make development_setup` (git repo at tmp/gitlab-test/)
    rm common/build_settings_test.go
    rm common/build_test.go
    rm executors/custom/custom_test.go

    # Timing-dependent test causes spurious failures on Hydra.
    # Might be fixed upstream in this MR: https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/6623
    # Try dropping it on next major version bump
    rm executors/kubernetes/internal/watchers/pod_test.go
  ''
  + lib.optionalString (!stdenv.buildPlatform.isx86_64) ''
    # Kubernetes tests actually work fine inside the network sandbox (they don't
    # expect real Kubernetes), but they fail on aarch64-linux because their
    # mocks expect x86_64
    rm executors/kubernetes/kubernetes_test.go
    rm executors/kubernetes/overwrites_test.go
  ''
  + lib.optionalString stdenv.buildPlatform.isDarwin ''
    # Darwin's sandbox blocks sendfile(2) during local HTTP PUT uploads
    substituteInPlace commands/helpers/cache_archiver_test.go \
      --replace-fail "func TestUploadExistingArchiveIfNeeded" "func OFF_TestUploadExistingArchiveIfNeeded"

    # Invalid bind arguments break Unix socket tests.
    substituteInPlace commands/wrapper_test.go \
      --replace-fail "func TestRunnerWrapperCommand_createListener" "func OFF_TestRunnerWrapperCommand_createListener"

    # No keychain access during build breaks X.509 certificate tests
    substituteInPlace helpers/certificate/x509_test.go \
      --replace-fail "func TestCertificate" "func OFF_TestCertificate"
    substituteInPlace network/client_test.go \
      --replace-fail "func TestClientInvalidSSL" "func OFF_TestClientInvalidSSL"
  '';

  postPatch = ''
    # 19.3 added docker-credential-{listonly,token}.sh and pinned/
    # docker-credential-pinned.sh next to docker-credential-bin.sh. All carry
    # "#!/usr/bin/env bash", which does not resolve in the sandbox, so the
    # credential-helper tests fail with "fork/exec ...: no such file or
    # directory". Patch the whole directory instead of naming one file, so
    # further additions are covered too.
    patchShebangs --build helpers/docker/auth/testdata
  ''
  # The kubernetes executor tests added in 19.3 execute the generated container
  # command for real. It begins with the runner's BashDetectShellScript, which
  # probes absolute paths and execs the first that exists: /usr/local/bin/bash,
  # /usr/bin/bash, /bin/bash, then the sh variants. No bash path exists in the
  # build sandbox and its root is read-only, so the script falls through to
  # /bin/sh (BusyBox ash). That reports exit 2 for a script it cannot open where
  # bash reports 127, and the test asserts 127. Point the test's own detect
  # script at a real bash so it exercises the bash pipe/exit-status semantics it
  # is about, instead of the sh fallback. Guarded by the same condition under
  # which prePatch removes this test file entirely.
  + lib.optionalString stdenv.buildPlatform.isx86_64 ''
    substituteInPlace executors/kubernetes/kubernetes_test.go \
      --replace-fail '[]byte(shells.BashDetectShellScript)' '[]byte("exec ${bash}/bin/bash \"$@\"\n")'
  '';

  excludedPackages = [
    # Nested dependency Go module, used with go.mod replace directive
    #
    # https://gitlab.com/gitlab-org/gitlab-runner/-/commit/57ea9df5d8a8deb78c8d1972930bbeaa80d05e78
    "./helpers/runner_wrapper/api"
    # Helper scripts for upstream Make targets, not intended for downstream consumers
    "./scripts"
  ];

  ldflags =
    let
      ldflagsPackageVariablePrefix = "gitlab.com/gitlab-org/gitlab-runner/common";
    in
    [
      "-X ${ldflagsPackageVariablePrefix}.NAME=gitlab-runner"
      "-X ${ldflagsPackageVariablePrefix}.VERSION=${finalAttrs.version}"
      "-X ${ldflagsPackageVariablePrefix}.REVISION=v${finalAttrs.version}"
    ];

  nativeCheckInputs = [
    gitMinimal
    writableTmpDirAsHomeHook
  ];

  preCheck = ''
    # Make the tests pass outside of GitLab CI
    export CI=0
  '';

  # Many tests start servers which bind to ports
  __darwinAllowLocalNetworking = true;

  postInstall = ''
    install packaging/root/usr/share/gitlab-runner/clear-docker-cache $out/bin
  '';

  doInstallCheck = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "GitLab Runner the continuous integration executor of GitLab";
    homepage = "https://docs.gitlab.com/runner";
    changelog = "https://gitlab.com/gitlab-org/gitlab-runner/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "gitlab-runner";
    maintainers = with lib.maintainers; [ zimbatm ];
    teams = [ lib.teams.gitlab ];
  };
})
