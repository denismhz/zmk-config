{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    zmk-nix,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    src = nixpkgs.lib.sourceFilesBySuffices self [".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"];
    zephyrDepsHash = "sha256-J1HGjbZQZZ6iFbFRDp4ChFCetD3ZIF9O4xUsQtvrBOE=";
  in {
    packages = forAllSystems (system: rec {
      default = firmware;

      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        buildInputs = [nixpkgs.python3Packages.setuptools];
        name = "enki42";

        inherit src zephyrDepsHash;
        board = "nice_nano_v2";
        shield = "enki42_%PART% nice_oled";
        parts = ["left" "right" "dongle"];
        centralPart = "dongle";
        enableZmkStudio = true;

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      settings-reset = zmk-nix.legacyPackages.${system}.buildKeyboard {
        name = "settings_reset";
        inherit src zephyrDepsHash;
        board = "nice_nano_v2";
        shield = "settings_reset";
      };

      prospector = zmk-nix.legacyPackages.${system}.buildKeyboard {
        name = "enki42-prospector";
        inherit src zephyrDepsHash;
        board = "seeeduino_xiao_ble";
        shield = "enki42_dongle prospector_adapter";
        enableZmkStudio = true;
      };

      flash = zmk-nix.packages.${system}.flash.override {inherit firmware;};
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
