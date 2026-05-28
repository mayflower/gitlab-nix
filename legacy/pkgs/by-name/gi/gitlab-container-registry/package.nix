{
  lib,
  buildGo124Module,
  fetchFromGitLab,
}:

buildGo124Module rec {
  pname = "gitlab-container-registry";
  version = "4.38.0";
  rev = "v${version}-gitlab";

  # nixpkgs-update: no auto update
  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "container-registry";
    inherit rev;
    hash = "sha256-LBEPiFbEM9RczEhflLKwt4+Y6IQ+TfQJE7fQxd/qIjc=";
  };

  vendorHash = "sha256-gaBys09Wyoi1+2yVBI9BlmpS2UNKg3Lq3/LbAK9WOw4=";

  excludedPackages = [
    "devvm/*"
  ];

  checkFlags =
    let
      skippedTests = [
        # requires internet
        "TestHTTPChecker"
        # requires s3 credentials/urls
        "TestS3DriverPathStyle"
        # flaky
        "TestPurgeAll"
      ];
    in
    [ "-skip=^${builtins.concatStringsSep "$|^" skippedTests}$" ];

  __darwinAllowLocalNetworking = true;

  meta = {
    description = "GitLab Docker toolset to pack, ship, store, and deliver content";
    license = lib.licenses.asl20;
    teams = with lib.teams; [
      gitlab
      cyberus
    ];
    platforms = lib.platforms.unix;
    mainProgram = "registry";
  };
}
