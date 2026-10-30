# gitlab-nix

Nix flake for GitLab CE packages and NixOS modules, pinned to specific GitLab
versions.

> This is primarily an internal tool for Mayflower's GitLab. It is public as a
> reference; use it for orientation, but expect no support or stability
> guarantees.

## Why

nixpkgs ships whatever GitLab version `nixos-unstable` currently has. That does
not always fit:

- New GitLab versions, including security patches, sometimes reach nixpkgs
  late.
- We deliberately stay off a new minor for a while, because the first month of
  a minor tends to bring more regressions.

gitlab-nix decouples the GitLab version from the system's nixpkgs: each release
tag carries exactly one GitLab version, built against a matching nixpkgs and
tested with the NixOS VM tests.

## Lines and tags

Like GitLab's maintenance policy, there are three lines: `latest`, `stable` and
`legacy` (currently only `legacy` is populated). Releases are tagged
`X.Y.Z+<line>`; a follow-up release of the same version is `X.Y.Z+<line>.N`.
Tags are never moved.

## Usage

```nix
# flake.nix
inputs.gitlab-nix.url = "github:mayflower/gitlab-nix/19.4.3+legacy.2";

# NixOS configuration
imports = [ inputs.gitlab-nix.nixosModules.default ];
nixpkgs.overlays = [ inputs.gitlab-nix.overlays.default ];
services.gitlab-nix.enable = true;
```

The modules are the nixpkgs ones with the option root renamed
(`services.gitlab` → `services.gitlab-nix`, `services.gitlab-runner` →
`services.gitlab-nix-runner`); unit names, user and `statePath` are unchanged.
Packages built on the pinned nixpkgs are available as
`legacyPackages.<system>.gitlab-nix`.

## Development

```sh
nix build .#gitlab   # build a package of the active line
nix flake check      # run the VM tests
```

[LINKS.md](LINKS.md) collects GitLab's release and upgrade-path references.

## License

[MIT](LICENSE)
