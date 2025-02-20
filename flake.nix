{
  description = "Simon’s Improved Layout Engine";

  # To make user overrides of the nixpkgs flake not take effect
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  # https://nixos.wiki/wiki/Flakes#Using_flakes_project_from_a_legacy_Nix
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self
    , nixpkgs
    , flake-utils
    , flake-compat
  }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
      # TODO: Should this be replaced with libtexpdf package from nixpkgs? or
      # should we keep it that way, so that it'd be easy to test new versions
      # of libtexpdf when developing?
      libtexpdf-src = builtins.fetchGit {
        url = "https://github.com/sile-typesetter/libtexpdf";
        rev = "${(pkgs.lib.fileContents "${self}/libtexpdf.git-rev")}";
      };
      # https://discourse.nixos.org/t/passing-git-commit-hash-and-tag-to-build-with-flakes/11355/2
      version_rev = if (self ? rev) then (builtins.substring 0 8 self.rev) else "dirty";
      # Use the expression from Nixpkgs instead of rewriting it here.
      sile = pkgs.sile.overrideAttrs(oldAttr: rec {
        version = "${(pkgs.lib.importJSON ./package.json).version}-${version_rev}-flake";
        src = builtins.filterSource
          (path: type: type != "directory" || baseNameOf path != ".git")
        ./.;
        # Add the libtexpdf src instead of the git submodule.
        preAutoreconf = ''
          rm -rf ./libtexpdf
          # From some reason without this flag, libtexpdf/ is unwriteable
          cp --no-preserve=mode -r ${libtexpdf-src} ./libtexpdf/
        '';
        # Pretend to be a tarball release so sile --version will not say `vUNKNOWN`.
        postAutoreconf = ''
          echo ${version} > .tarball-version
        '';
        # Don't build the manual as it's time consuming, and it requires fonts
        # that are not available in the sandbox due to internet connection
        # missing.
        configureFlags = pkgs.lib.lists.remove "--with-manual" oldAttr.configureFlags;
        nativeBuildInputs = oldAttr.nativeBuildInputs ++ [
          pkgs.autoreconfHook
        ];
        # TODO: This switch between the hooks can be moved to Nixpkgs'
        postPatch = oldAttr.preConfigure;
        preConfigure = "";
        meta = oldAttr.meta // {
          changelog = "https://github.com/sile-typesetter/sile/raw/master/CHANGELOG.md";
        };
      });
    in rec {
      devShell = pkgs.mkShell {
        inherit (sile) checkInputs nativeBuildInputs buildInputs;
      };
      packages.sile = sile;
      defaultPackage = sile;
      apps.sile = {
        type = "app";
        program = "${sile}/bin/sile";
      };
      defaultApp = apps.sile;
    }
  );
}
