{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    themes = [ "rebel_hangar" "starkiller_hangar" ];

    mkTheme = name: pkgs.stdenv.mkDerivation {
      pname = "grub-theme-${name}";
      version = self.shortRev or self.dirtyShortRev or "dirty";
      
      src = ./${name};
      
      installPhase = ''
        mkdir -p $out
        cp -r * $out/
      '';
    };
  in 
  {
    packages.${system} = pkgs.lib.genAttrs themes mkTheme;
  };
}
