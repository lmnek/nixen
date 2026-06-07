# ~/repos/nixen/flake.nix
{
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        disko = {
		    url = "github:nix-community/disko";
		    inputs.nixpkgs.follows = "nixpkgs";
        };

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		noctalia = {
			url = "github:noctalia-dev/noctalia-shell";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		zen-browser = {
			url = "github:youwen5/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};

        llm-agents.url = "github:numtide/llm-agents.nix";
	};


    # for binary caches (so far only llm-agents)
    nixConfig = {
        extra-substituters = [ "https://cache.numtide.com" ];
        extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
    };

	outputs = { self, nixpkgs, disko, home-manager, ... }@inputs:
		let 
		system="x86_64-linux";
	in {
		nixosConfigurations.msi = nixpkgs.lib.nixosSystem { # msi = hostname
			inherit system;
			specialArgs = { inherit inputs; }; # makes `inputs` visible in configuration.nix
				modules = [
					disko.nixosModules.disko
					inputs.home-manager.nixosModules.default
					./disko.nix
					./hardware-configuration.nix
					./configuration.nix
				];
		};
		homeConfigurations.lmnk = home-manager.lib.homeManagerConfiguration {
			pkgs = nixpkgs.legacyPackages.${system};
			modules = [ ./home.nix ];
		};
	};
}
