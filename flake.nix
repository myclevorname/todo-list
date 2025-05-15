{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        packages.default = pkgs.stdenv.mkDerivation (final: {
          name = "todo";
          src = self;
          postPatch = ''
            ln -s ${pkgs.callPackage ./deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
          '';
          postFixup = ''
            patchelf $out/bin/todo \
              --add-rpath ${pkgs.lib.makeLibraryPath final.buildInputs}
          '';
          nativeBuildInputs = with pkgs; [ zig.hook wayland-scanner ];
          buildInputs = with pkgs; [ egl-wayland libGL wayland libxkbcommon ];
        });
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ zig wayland-scanner ];
          buildInputs = with pkgs; [ egl-wayland libGL wayland libxkbcommon ];
        };
      }
    );
}
