{
  description = "Szmelc AUR (SAUR): build, publish and serve a self-updating pacman repository with stable and experimental channels";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: rec {
        saur = pkgs.stdenvNoCC.mkDerivation {
          pname = "saur";
          version = "0.2.1";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper pkgs.installShellFiles ];
          dontBuild = true;
          # The script is also mounted into Arch containers: keep its /usr/bin/env shebang.
          dontPatchShebangs = true;
          installPhase = ''
            runHook preInstall
            install -Dm755 bin/saur $out/bin/saur
            wrapProgram $out/bin/saur --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [
              bash git curl jq gnutar gzip coreutils findutils gawk gnused gnugrep util-linux libarchive
            ])}
            installShellCompletion --cmd saur \
              --bash <($out/bin/saur completion bash) \
              --zsh <($out/bin/saur completion zsh) \
              --fish <($out/bin/saur completion fish)
            install -Dm644 LICENSE README.md saur.conf -t $out/share/doc/saur
            runHook postInstall
          '';
          meta = {
            description = "Build, publish and serve Szmelc AUR (SAUR), a self-updating pacman repository";
            homepage = "https://szmelc-inc.github.io/SAUR";
            license = pkgs.lib.licenses.mit;
            mainProgram = "saur";
            platforms = pkgs.lib.platforms.linux;
          };
        };
        default = saur;
      });

      apps = forAll (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.saur}/bin/saur";
        };
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ bash git curl jq gh shellcheck python3 libarchive ];
        };
      });
    };
}
