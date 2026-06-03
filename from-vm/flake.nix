{
  description = "A flake to symlink .config directory";

    inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
};

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
	let 
		system="x86_64-linux";
	in {
	    # nixos - hostname 
	    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
		inherit system;
		modules = [
			./configuration.nix
		];
	      };
		homeConfigurations.lmnk = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [ ./home.nix ];
    };
  };
}
