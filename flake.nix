{
  description = "Build a cargo project without extra checks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      system = "aarch64-darwin";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      craneLib = inputs.crane.mkLib pkgs;
      commonArgs = {
        src = craneLib.cleanCargoSource ./.;
        strictDeps = true;
      };
      macmon = craneLib.buildPackage (
        commonArgs
        // {
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        }
      );
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          rustfmt.enable = true;
        };
      };
    in
    {
      formatter.${system} = treefmtEval.config.build.wrapper;
      checks.${system} = {
        formatting = treefmtEval.config.build.check inputs.self;
        inherit macmon;
      };
      packages.${system}.default = macmon;
      devShells.${system}.default = craneLib.devShell {
        inputsFrom = [ macmon ];
        checks = inputs.self.checks.${system};
        packages = with pkgs; [ bacon ];
        env = {
          RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
        };
      };
    };
}
