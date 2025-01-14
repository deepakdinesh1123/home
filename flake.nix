{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  description = "Portfolio";

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        devDependencies = with pkgs; [ 
            uv
          ];

        devShells = {
          default = pkgs.mkShell {
            buildInputs = devDependencies;
          };
        };
    }
  );
}