final: prev:
let
  gitlab-nix = {
    gitaly = final.callPackage ./pkgs/by-name/gi/gitaly/package.nix { };
    gitlab = final.callPackage ./pkgs/by-name/gi/gitlab/package.nix { };
    gitlab-workhorse = final.callPackage ./pkgs/by-name/gi/gitlab/gitlab-workhorse/default.nix { };
    gitlab-container-registry = final.callPackage ./pkgs/by-name/gi/gitlab-container-registry/package.nix { };
    gitlab-elasticsearch-indexer = final.callPackage ./pkgs/by-name/gi/gitlab-elasticsearch-indexer/package.nix { };
    gitlab-pages = final.callPackage ./pkgs/by-name/gi/gitlab-pages/package.nix { };
    gitlab-runner = final.callPackage ./pkgs/by-name/gi/gitlab-runner/package.nix { };
    gitlab-shell = final.callPackage ./pkgs/by-name/gi/gitlab-shell/package.nix { };
  };
in
gitlab-nix // { inherit gitlab-nix; }
