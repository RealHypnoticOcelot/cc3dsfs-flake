{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... } @ inputs:
  let
    packageName = "cc3dsfs-wrapped";
    version = "1.3.0.1";
    forSupportedSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux" # Only supporting one system, because of this BellSoft Liberica thing
      "i686-linux"
      "aarch64-linux"
      "riscv64-linux"
      "aarch64-darwin"
    ];
    forSupportedPackages = forSupportedSystems ( # Create a list of nixpkgs objects
      system:
      import nixpkgs {
        inherit system;
      }
    );
  in
  {
    packages = forSupportedSystems (system:
      let
        cc3dsfs-src = forSupportedPackages.${system}.fetchFromGitHub {
          owner = "Lorenzooone";
          repo = "cc3dsfs";
          tag = version;
          sha256 = "sha256-9oSliq5QORrFR+OC082yAUOHUadUZIwDqHMGygaHQKQ=";
        };
        sfml-src = forSupportedPackages.${system}.fetchFromGitHub {
          owner = "SFML";
          repo = "SFML";
          tag = "3.1.0";
          sha256 = "sha256-DNtOFeabU3yY1AoNS2kKZZAKdYNgPNkqG32PhY6YBDY=";
        };
        libusb-cmake-src = forSupportedPackages.${system}.fetchFromGitHub {
          owner = "libusb";
          repo = "libusb-cmake";
          tag = "v1.0.30-0";
          sha256 = "sha256-okywuaQGmVbMu1u/9fwX1UrhiT/6maPYOB/1HypjimY=";
        };
        sheenbidi-src = forSupportedPackages.${system}.fetchFromGitHub {
          owner = "Tehreer";
          repo = "SheenBidi";
          tag = "v3.0.0";
          sha256 = "sha256-e/24MlRX+93b34qD2V1+2XVhMh4WEy2qvt9Rgvybwxs=";
        };
      in
      {
      default = forSupportedPackages.${system}.stdenv.mkDerivation (finalAttrs: {
        pname = packageName;
        version = version;
        src = cc3dsfs-src;

        desktopItems = [(
          forSupportedPackages.${system}.makeDesktopItem {
            name = packageName;
            exec = packageName;
            icon = ./3ds.png;
            desktopName = "cc3dsfs";
            genericName = "Video capture software for (3)DS(i) capture cards";
          }
        )];

        nativeBuildInputs = with forSupportedPackages.${system}.pkgs; [
          makeWrapper
          cmake
          libgcc
          git
          copyDesktopItems
        ];

        buildInputs = with forSupportedPackages.${system}.pkgs; [
          libxrandr.dev
          libxcursor.dev
          libgudev.dev
          flac.dev
          libvorbis.dev
          mesa-gl-headers
          libdrm.dev
          libgbm
          libxft.dev
          harfbuzz.dev
          xorg-server.dev
          libxi.dev
        ];


        cmakeFlags = [
          "-DCMAKE_BUILD_TYPE=Release"
          "-DFETCHCONTENT_SOURCE_DIR_SFML=${sfml-src}"
          "-DFETCHCONTENT_SOURCE_DIR_LIBUSB=${libusb-cmake-src}"
          "-DFETCHCONTENT_SOURCE_DIR_SHEENBIDI=${sheenbidi-src}"
        ];

        configPhase = ''
          cmake -B build
        '';

        buildPhase = ''
          cmake --build . --config Release
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          cp bin/cc3dsfs $out/bin/cc3dsfs
          makeWrapper $out/bin/cc3dsfs $out/bin/${packageName} \
            --prefix LD_LIBRARY_PATH : ${forSupportedPackages.${system}.lib.makeLibraryPath [ forSupportedPackages.${system}.pkgs.libpulseaudio ]}

          mkdir -p $out/lib/udev/rules.d
          cp ../usb_rules/*.rules $out/lib/udev/rules.d/

          runHook postInstall
        '';
        });
      }
    );
  };
}
# Run `nix develop` to enter the shell, and run `exit` to leave the shell