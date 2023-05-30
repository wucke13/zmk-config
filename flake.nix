{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zephyr-flake-utils = {
      url = "github:wucke13/zephyr-flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zmk = {
      url = "github:zmkfirmware/zmk";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.devshell.overlays.default
            ];
          };
        in
        rec {
          devShell =
            with inputs.zephyr-flake-utils.packages.${system};
            let
              sdk = zephyr-sdk-0_16_1;
              toolchain = toolchain-arm-0_16_1;
            in
            pkgs.mkShell {
              ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
              ZEPHYR_SDK_INSTALL_DIR = sdk;

              nativeBuildInputs = with pkgs; [
                sdk
                toolchain
                inputs.zephyr-flake-utils.packages.${system}.zephyr-python
                cmake
                ninja
                dtc

                nushell
              ];
              shellHook = ''
                exec nu --execute "source ./script.nu"
              '';
            };
        }
      );
}
