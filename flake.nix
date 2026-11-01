{
  description = "polyglot — one source tree, four build-system adapters";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      version = nixpkgs.lib.removeSuffix "\n" (builtins.readFile ./version.txt);
    in {
      packages = forAllSystems (pkgs:
        let
          python = pkgs.python3.withPackages (ps: [ ps.pip ps.setuptools ps.wheel ]);
          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = path: type:
              let base = baseNameOf path;
              in !(builtins.elem base [ "target" "dist" "dist-buck" "node_modules" "buck-out" "result" ".nx" ])
                && builtins.match "bazel-.*" base == null;
          };
          release = pkgs.stdenv.mkDerivation {
            pname = "polyglot";
            inherit version src;

            nativeBuildInputs = [
              pkgs.nodejs
              pkgs.cargo
              pkgs.rustc
              python
              pkgs.unzip
            ];

            # The manifest hashes the artifacts, so do not let fixup rewrite them
            # after they are measured.
            dontFixup = true;
            dontStrip = true;

            buildPhase = ''
              export HOME=$TMPDIR
              export CARGO_HOME=$TMPDIR/cargo
              export npm_config_cache=$TMPDIR/npm
              export POLYGLOT_OFFLINE=1
              export RELEASE_VERSION=${version}
              bash scripts/build-release.sh
            '';

            installPhase = ''
              mkdir -p $out
              cp -r dist/. $out/
            '';

            meta.description = "Polyglot release artifacts";
          };
        in {
          inherit release;
          default = release;
        });

      checks = forAllSystems (pkgs: {
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.release;
      });
    };
}
