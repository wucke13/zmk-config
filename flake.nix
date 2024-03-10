{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zephyr-flake-utils.url = "github:wucke13/zephyr-flake-utils";
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
              (final: prev: {
                npmlock2nix = import inputs.npmlock2nix { pkgs = prev; };
              })
            ];
          };
        in
        rec {

          packages.zmk-viewer = with pkgs; buildGoModule rec {
            pname = "zmk-viewer";
            version = "1.5.0";
            src = fetchFromGitHub {
              owner = "MrMarble";
              repo = pname;
              rev = "v${version}";
              hash = "sha256-gyu0bf5XUaBWxtpoLeFIbPGqPPD2bJjEeyjfLdFy0hA=";
            };
            vendorHash = "sha256-G0p0VYCHpQE/htq452bWUZbFCxAkvwk76paiG+i72cg=";

            meta = with lib; {
              description = "Cli tool to generate preview images from a zmk .keymap file";
              homepage = "https://github.com/MrMarble/zmk-viewer";
              license = licenses.mit;
              maintainers = with maintainers; [ wucke13 ];
            };
          };


          devShell =
            with inputs.zephyr-flake-utils.packages.${system};
            let
              sdk = zephyr-sdk-0_16_1;
              toolchain = toolchain-arm-0_16_1;
            in
            pkgs.mkShell {
              ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
              ZEPHYR_SDK_INSTALL_DIR = sdk;

              # comment out to use a local zmk
              ZMK_PATH = inputs.zmk;

              nativeBuildInputs = with pkgs; [
                sdk
                toolchain
                inputs.zephyr-flake-utils.packages.${system}.zephyr-python
                cmake
                ninja
                dtc

                nodejs
                nushell
                udiskie
              ];
              # https://zmk.dev/docs/development/setup
              # cd zmk && west init -l app/
            };
        }
      );
}
