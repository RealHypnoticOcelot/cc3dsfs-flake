{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cc3dsfs-src = {
      url = "github:Lorenzooone/cc3dsfs";
      flake = false;
    };
    sfml = {
      url = "github:SFML/SFML";
      flake = false;
    };
    libusb-cmake = {
      url = "github:libusb/libusb-cmake";
      flake = false;
    };
    sheenbidi = {
      url = "github:Tehreer/SheenBidi";
      flake = false;
    };
  };

  outputs = { nixpkgs, cc3dsfs-src, sfml, libusb-cmake, sheenbidi, ... } @ inputs:
  let
    packageName = "cc3dsfs-wrapped";
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
      {
      default = forSupportedPackages.${system}.stdenv.mkDerivation (finalAttrs: {
        pname = packageName;
        version = "1.3.0.2M";
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
          "-DFETCHCONTENT_SOURCE_DIR_SFML=${sfml}"
          "-DFETCHCONTENT_SOURCE_DIR_LIBUSB=${libusb-cmake}"
          "-DFETCHCONTENT_SOURCE_DIR_SHEENBIDI=${sheenbidi}"
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