final: prev:
let
  gitlab-nix = {
    gitlab = final.callPackage ./pkgs/by-name/gi/gitlab/package.nix { };
    gitaly = final.callPackage ./pkgs/by-name/gi/gitaly/package.nix { };
    gitlab-shell = final.callPackage ./pkgs/by-name/gi/gitlab-shell/package.nix { };
    gitlab-pages = final.callPackage ./pkgs/by-name/gi/gitlab-pages/package.nix { };
    gitlab-workhorse = final.callPackage ./pkgs/by-name/gi/gitlab/gitlab-workhorse/default.nix { };
    gitlab-container-registry = final.callPackage ./pkgs/by-name/gi/gitlab-container-registry/package.nix { };
    gitlab-elasticsearch-indexer = final.callPackage ./pkgs/by-name/gi/gitlab-elasticsearch-indexer/package.nix { };
    gitlab-runner = final.callPackage ./pkgs/by-name/gi/gitlab-runner/package.nix { };
  };
in
gitlab-nix // { inherit gitlab-nix; }
